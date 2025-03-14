//
//  MastodonPostDetailViewController.swift
//
//  iMast https://github.com/cinderella-project/iMast
//
//  Created by rinsuki on 2019/07/28.
//
//  ------------------------------------------------------------------------
//
//  Copyright 2017-2019 rinsuki and other contributors.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit
import Mew
import SnapKit
import Ikemen
import iMastiOSCore

class MastodonPostDetailViewController: UITableViewController, Instantiatable, Injectable {
    typealias Input = MastodonPost
    typealias Environment = MastodonUserToken
    let environment: Environment
    var input: Input
    
    enum Row {
        case boostedUser
        case content
        case poll
        case reactions
        case reactionBar
    }
    
    var dataSource: [Row] = []
    
    required init(with input: Input, environment: Environment) {
        self.input = input
        self.environment = environment
        super.init(style: .grouped)
        self.generateDataSource()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func generateDataSource() {
        var dataSource: [Row] = []
        if input.repost != nil {
            dataSource.append(.boostedUser)
        }
        dataSource.append(.content)
        if input.originalPost.poll != nil {
            dataSource.append(.poll)
        }
        if input.originalPost.repostCount > 0 || input.originalPost.favouritesCount > 0 || input.application != nil {
            dataSource.append(.reactions)
        }
        dataSource.append(.reactionBar)
        self.dataSource = dataSource
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 0.01)) // remove header space
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        TableViewCell<MastodonPostDetailBoostedUserViewController>.register(to: tableView)
        TableViewCell<MastodonPostDetailContentViewController>.register(to: tableView)
        TableViewCell<MastodonPostDetailPollViewController>.register(to: tableView)
        TableViewCell<MastodonPostDetailReactionsViewController>.register(to: tableView)
        TableViewCell<MastodonPostDetailReactionBarViewController>.register(to: tableView)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.reload), for: .valueChanged)
        tableView.refreshControl = refreshControl

        self.title = "投稿詳細"
        navigationItem.largeTitleDisplayMode = .always
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "文脈", style: .plain, target: self, action: #selector(openBunmyakuVC))
        self.input(input)
    }
    
    @objc func reload() {
        MastodonEndpoint.GetPost(post: input).request(with: environment).then { [weak self] res in
            guard let strongSelf = self else { return }
            strongSelf.input(res)
            strongSelf.tableView.refreshControl?.endRefreshing()
            print("end refresh")
        }
    }
    
    @objc func openBunmyakuVC() {

        let bunmyakuVC = BunmyakuTableViewController.instantiate(.plain, environment: environment)
        bunmyakuVC.basePost = input.originalPost
        navigationController?.pushViewController(bunmyakuVC, animated: true)
    }
    
    func input(_ input: Input) {
        self.input = input
        self.generateDataSource()
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let source = self.dataSource[indexPath.row]
        switch source {
        case .boostedUser:
            cell = TableViewCell<MastodonPostDetailBoostedUserViewController>.dequeued(
                from: tableView,
                for: indexPath,
                input: self.input.account,
                parentViewController: self
            )
            cell.accessoryType = .disclosureIndicator
        case .content:
            cell = TableViewCell<MastodonPostDetailContentViewController>.dequeued(
                from: tableView,
                for: indexPath,
                input: self.input,
                output: { [weak self] in
                    guard let tableView = self?.tableView else { return }
                    tableView.beginUpdates()
                    tableView.endUpdates()
                },
                parentViewController: self
            )
        case .poll:
            cell = TableViewCell<MastodonPostDetailPollViewController>.dequeued(
                from: tableView,
                for: indexPath,
                input: self.input.originalPost,
                parentViewController: self
            )
        case .reactions:
            cell = TableViewCell<MastodonPostDetailReactionsViewController>.dequeued(
                from: tableView,
                for: indexPath,
                input: self.input.originalPost,
                parentViewController: self
            )
        case .reactionBar:
            cell = TableViewCell<MastodonPostDetailReactionBarViewController>.dequeued(
                from: tableView,
                for: indexPath,
                input: self.input.originalPost,
                parentViewController: self
            )
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let source = self.dataSource[indexPath.row]
        switch source {
        case .boostedUser:
            let vc = UserProfileTopViewController.instantiate(input.account, environment: environment)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
