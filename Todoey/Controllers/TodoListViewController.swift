//
//  ViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 1/27/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import BEMCheckBox

class TodoListViewController: UITableViewController, UISearchBarDelegate, TodoCellDelegate {
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    var todoItems: Results<Item>?
    let realm = try! Realm()

    @IBOutlet weak var searchBar: UISearchBar!


    // MARK: - View Controller Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = selectedCategory?.name ?? "Todo Items"
    }

    override func viewWillAppear(_ animated: Bool) {
        if let bacgroundColor = UIColor(hexString: selectedCategory?.color), let textColor = UIColor(contrastingBlackOrWhiteColorOn: bacgroundColor, isFlat: true) {
            // Customize the search bar
            searchBar.barTintColor = bacgroundColor
            searchBar.tintColor = textColor

            // Customize the navigation bar
            guard let navBar = navigationController?.navigationBar else {fatalError("Navigation Controller does not exists.")}
            navBar.barTintColor = bacgroundColor
            navBar.tintColor = textColor
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
            navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
            navBar.prefersLargeTitles = true
            navigationItem.rightBarButtonItem?.tintColor = textColor
        }
    }


    // MARK: - Tableview Delegate and Datasource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoTableViewCell
        cell.delegate = self
        cell.checkBoxDelegate = self
        cell.itemIndex = indexPath.row
        if let item = todoItems?[indexPath.row] {
            cell.title.text = item.title
            cell.checkBox.setOn(item.done, animated: true)
        }

        // Set a gradient background color and contrasting text color
        let darkness = calculateDarkness(forIndex: indexPath.row)
        if let backgroundColor = UIColor(hexString: selectedCategory?.color)?.darken(byPercentage: darkness), let textColor = UIColor(contrastingBlackOrWhiteColorOn: backgroundColor, isFlat: true) {
            cell.title?.textColor = textColor
            cell.tintColor = textColor
            cell.backgroundColor = backgroundColor
            cell.checkBox.tintColor = textColor
            cell.checkBox.onTintColor = textColor
            cell.checkBox.onFillColor = textColor
            cell.checkBox.onCheckColor = backgroundColor
        }

        return cell
    }

    func calculateDarkness(forIndex index: Int) -> CGFloat {
        if todoItems?.count ?? 0 >= 10 {
            return CGFloat(index) / CGFloat(todoItems!.count)
        } else {
            return CGFloat(index) / 10.0
        }
    }


    // MARK: - TodoCell Delegate Methods

    func checkBoxTapped(cell: TodoTableViewCell) {
        updateItem(atIndex: cell.itemIndex)
        tableView.reloadRows(at: [IndexPath(row: cell.itemIndex, section: 0)], with: .automatic)
    }


    // MARK: - UISearchBarDelegate Methods

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            searchBar.text = ""
            searchBar.showsCancelButton = false
        }
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
        loadItems()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterItems(by: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }


    // MARK: - IBActions

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            if text != nil && text != "" {
                // Create a new Item
                let newItem = Item()
                newItem.title = text!
                self.saveItem(newItem)
            }
        }
        alert.addTextField { (alertTextField) in
            // Customize a textField
            alertTextField.placeholder = "Create new item"
            alertTextField.autocapitalizationType = .sentences
            alertTextField.enablesReturnKeyAutomatically = true
            alertTextField.returnKeyType = .done
            textField = alertTextField
        }
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        alert.preferredAction = addAction
        self.present(alert, animated: true, completion: nil)
    }


    // MARK: - Realm Methods

    func saveItem(_ item: Item) {
        if let currentCategory = self.selectedCategory {
            do {
                try self.realm.write {
                    realm.add(item)
                    currentCategory.items.append(item)
                }
            } catch {
                print("Error saving a new Item in realm, \(error)")
            }
            tableView.reloadData()
        }
    }

    func deleteItem(_ item: Item) {
        do {
            try realm.write {
                realm.delete(item)
            }
        } catch {
            print("Error deleting Item in realm, \(error)")
        }
    }

    func updateItem(atIndex index: Int) {
        if let item = todoItems?[index] {
            do {
                try realm.write {
                    item.done = !item.done
                }
            } catch {
                print("Error updating Item in realm, \(error)")
            }
        }
    }

    func loadItems() {
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }

    func filterItems(by searchText: String = "") {
        if searchText != "" {
            todoItems = selectedCategory?.items.filter("title CONTAINS[cd] %@", searchText).sorted(byKeyPath: "dateCreated", ascending: true)
            tableView.reloadData()
        } else {
            loadItems()
        }
    }
}


// MARK: - SwipeTableViewCell Delegate Methods

extension TodoListViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete", handler: {
            (action: SwipeAction, indexPath: IndexPath) in
            // Display an Alert for confirmation
            let message = "Are you sure you want to DELETE this item?"
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
            let cancelBtn = UIAlertAction(title: "Cancel", style: .cancel) { (cancel) in
                action.fulfill(with: .reset)
            }
            let removeBtn = UIAlertAction(title: "Delete", style: .destructive) { (remove) in
                if let item = self.todoItems?[indexPath.row] {
                    self.deleteItem(item)
                    action.fulfill(with: .delete)
                }
            }
            alert.addAction(removeBtn)
            alert.addAction(cancelBtn)
            self.present(alert, animated: true, completion: nil)
        })

        // Customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")

        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive(automaticallyDelete: false)
        options.transitionStyle = .border
        return options
    }
}
