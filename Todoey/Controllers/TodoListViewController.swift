//
//  ViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 1/27/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import CoreData
import ChameleonFramework
import SwipeCellKit
import BEMCheckBox

class TodoListViewController: UITableViewController, UISearchBarDelegate, TodoCellDelegate {
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    var itemArray = [Item]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @IBOutlet weak var searchBar: UISearchBar!


    // MARK: - View Controller Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = selectedCategory?.name ?? "Todo Items"
    }

    override func viewWillAppear(_ animated: Bool) {
        // Set the color on the search bar and navigation bar
        if let bacgroundColor = UIColor(hexString: selectedCategory?.color), let textColor = UIColor(contrastingBlackOrWhiteColorOn: bacgroundColor, isFlat: true) {
            searchBar.barTintColor = bacgroundColor
            searchBar.tintColor = textColor

            guard let navBar = navigationController?.navigationBar else {fatalError("Navigation Controller does not exists.")}
            navBar.barTintColor = bacgroundColor
            navBar.tintColor = textColor
            navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
            navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
            navBar.prefersLargeTitles = true
            navigationItem.rightBarButtonItem?.tintColor = textColor
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveItems()
    }


    // MARK: - Tableview Delegate and Datasource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath) as! TodoTableViewCell
        let item = itemArray[indexPath.row]
        cell.delegate = self
        cell.checkBoxDelegate = self
        cell.itemIndex = indexPath.row
        cell.title.text = item.title
        cell.checkBox.setOn(item.done, animated: true)

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
        if itemArray.count >= 10 {
            return CGFloat(index) / CGFloat(itemArray.count)
        } else {
            return CGFloat(index) / 10.0
        }
    }


    // MARK: - TodoCell Delegate Methods

    func checkBoxTapped(cell: TodoTableViewCell) {
        itemArray[cell.itemIndex].done = !itemArray[cell.itemIndex].done
        saveItems()
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
        filterItems(by: searchText)
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
            if text != "" {
                // Create a new Item
                let newItem = Item(context: self.context)
                newItem.title = textField.text
                newItem.parentCategory = self.selectedCategory

                self.itemArray.append(newItem)
                self.saveItems()
            }
        }
        alert.addTextField { (alertTextField) in
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


    // MARK: - Core Data Methods

    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        tableView.reloadData()
    }

    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest()) {
        if request.predicate == nil {
            request.predicate = NSPredicate(format: "parentCategory == %@", selectedCategory!)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        }

        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }

    func filterItems(by searchText: String) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ AND parentCategory.name MATCHES %@", searchText, selectedCategory!.name!)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        }
        loadItems(with: request)
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
                self.context.delete(self.itemArray[indexPath.row])
                self.itemArray.remove(at: indexPath.row)
                action.fulfill(with: .delete)
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
