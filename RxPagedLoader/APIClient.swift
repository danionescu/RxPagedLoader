//
//  APIClient.swift
//  RxPagedLoader
//
//  Created by Dan Ionescu on 14/06/16.
//  Copyright © 2016 Alt Tab. All rights reserved.
//

import Foundation

import RxSwift
import Fakery

struct Product {
    var name: String
    var price: Double
    var category: String
}

struct APIResultListState<Item> {
    var loadedItems: [Item]
    let totalCount: Int
    let hasMore:Bool
}

class APIClient {

    var fakeProducts: [[String:AnyObject]]!

    let fetchDuration: RxTimeInterval = 1

    static let emptyProductsResult = APIResultListState<Product>(loadedItems: [], totalCount: Int.max, hasMore: true)

    func populateFakeProducts(totalCount: Int) {
        fakeProducts = []
        let faker = Faker();
        for _ in 0..<totalCount {
            fakeProducts.append([
                "name": faker.commerce.productName(),
                "category": faker.commerce.department(),
                "price": round(faker.number.randomDouble(min: 0.19, max: 100) * 100) / 100
                ])
        }
    }

    func fetchProducts(offset offset: Int, limit: Int, loadTrigger: Observable<Void>) -> Observable<APIResultListState<Product>> {
        return fetchProductsRecursively(
            lastResult: APIClient.emptyProductsResult,
            offset: offset,
            limit: limit,
            loadTrigger: loadTrigger)
    }

    func fetchProductsRecursively(lastResult lastResult: APIResultListState<Product>, offset: Int, limit: Int, loadTrigger: Observable<Void>) -> Observable<APIResultListState<Product>> {
        return fetchProducts(offset: offset, limit: limit).flatMap { result -> Observable<APIResultListState<Product>> in
            var currentResult = result
            currentResult.loadedItems = lastResult.loadedItems + result.loadedItems

            if( !currentResult.hasMore ) {
                return Observable.just(currentResult)
            }

            return [
                Observable.just(currentResult),
                Observable.never().takeUntil(loadTrigger),
                self.fetchProductsRecursively(lastResult: currentResult, offset: offset + limit, limit: limit, loadTrigger: loadTrigger)
            ].concat()
        }
    }

    private func fetchProducts(offset offset: Int, limit: Int) -> Observable<APIResultListState<Product>> {
        return Observable<Int>
            .timer(fetchDuration, scheduler: MainScheduler.instance)
            .map { (val) -> APIResultListState<Product> in
                var products : [Product]

                var hasMore = false
                if offset < self.fakeProducts.count {
                    let lastOffset = min(self.fakeProducts.count, offset + limit) - 1
                    products = self.fakeProducts[offset...lastOffset].map{ product -> Product in
                        let name = product["name"] as! String
                        let price = product["price"] as! Double
                        let category = product["category"] as! String
                        return Product(name: name, price: price, category: category)
                    }

                    hasMore = lastOffset < self.fakeProducts.count - 1;
                } else {
                    products = []
                }

                return APIResultListState(loadedItems: products, totalCount: self.fakeProducts.count, hasMore: hasMore)
        }
    }

}