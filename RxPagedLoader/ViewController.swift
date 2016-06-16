//
//  ViewController.swift
//  RxPagedLoader
//
//  Created by Dan Ionescu on 14/06/16.
//  Copyright © 2016 Alt Tab. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class ViewController: UIViewController {
    let apiClient: APIClient = {
        $0.populateFakeProducts(50)
        return $0
    }(APIClient())

    let disposeBag = DisposeBag()

    let itemsPerPage = 10

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()

        // dataSource
        let dataSource = RxTableViewSectionedReloadDataSource<LoaderSectionModel>()
        setupDataSource(dataSource)

        // logic
        let scrollToBottom = tableView.rx_contentOffset
            .flatMap { [unowned self] offset in
                (offset.y + self.tableView.frame.size.height + 50 > self.tableView.contentSize.height)
                    ? Observable.just()
                    : Observable.empty()
        }

        let fetchProducts = apiClient.fetchProducts(offset: 0, limit: itemsPerPage, loadTrigger: scrollToBottom)

        let refreshButtonTap = refreshBarButtonItem.rx_tap.startWith(())

        let fetchProductsOnRefresh = refreshButtonTap.flatMapLatest { () -> Observable<APIResultListState<Product>> in
            return fetchProducts
        }

        Observable.of(
            fetchProductsOnRefresh,
            refreshButtonTap.map {_ in APIClient.emptyProductsResult} // empties the table view on refresh start
            )
            .merge()
            .map(self.sectionsFromResult)
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)


        // weird top space on reload when scrolledDown due to tableView.contentOffset
        let delay = refreshButtonTap.flatMap { _ in
            return Observable<Int>.timer(0.01, scheduler: MainScheduler.instance)
        }

        [refreshButtonTap.map { _ in ()}, delay.map{ _ in () }]
            .toObservable()
            .merge()
            .subscribeNext { [unowned self] _ in
                self.tableView.contentOffset = CGPoint(x: 0, y: -self.tableView.contentInset.top)
            }
            .addDisposableTo(disposeBag)
    }

    func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
    }

    func setupDataSource(dataSource: RxTableViewSectionedReloadDataSource<LoaderSectionModel>) {
        dataSource.configureCell = { (dataSource, tableView, indexPath, _) in
            let section = dataSource.sectionAtIndex(indexPath.section)

            switch section {
            case .ItemsSection:
                let product = dataSource.itemAtIndexPath(indexPath) as! Product
                let cell = tableView.dequeueReusableCellWithIdentifier("ProductCell", forIndexPath: indexPath) as! ProductTableViewCell
                cell.viewModel = ProductViewModel(product: product)

                // debug purpose only
                cell.nameLabel.text = String(indexPath.row + 1) + ". " + (cell.nameLabel.text ?? "")

                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier("LoaderCell", forIndexPath: indexPath) as! LoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }

        dataSource.canEditRowAtIndexPath = { _ in
            return false
        }
    }

    func sectionsFromResult(result: APIResultListState<Product>) -> [LoaderSectionModel] {
        var sections: [LoaderSectionModel] = []

        if result.loadedItems.count > 0 {
            sections.append(.ItemsSection(items: result.loadedItems))
        }

        if result.hasMore {
            sections.append(.LoaderSection);
        }

        return sections
    }

}

struct ProductViewModel {
    let name: String
    let price: String
    let category: String

    let product: Product

    init(product: Product) {
        self.product = product

        name = product.name
        price = "$\(String(format: "%.2f", product.price))"
        category = product.category
    }
}

enum LoaderSectionModel {
    case ItemsSection(items:[Product])
    case LoaderSection
}

extension LoaderSectionModel: SectionModelType {
    typealias Item = Any

    var items: [Any] {
        switch self {
        case let .ItemsSection(items: items):
            return items.map {$0}
        case .LoaderSection:
            return [""]
        }
    }

    init(original: LoaderSectionModel, items: [Item]) {
        self = original
    }
}


