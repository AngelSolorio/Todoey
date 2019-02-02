//
//  ViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 1/27/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController, UISearchBarDelegate {
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    var itemArray = [Item]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sets the TableViewFooter to avoid extra separator lines in empty rows 
        let footerView = UIView(frame: CGRect(x: 1.0, y: 1.0, width: 0.5, height: 0.5))
        footerView.backgroundColor = .lightGray
        tableView.tableFooterView = footerView
    }


    // MARK: - Tableview Delegate and Datasource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath)
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let alert = UIAlertController(title: nil, message: "Are you sure you want to DELETE this item?", preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let removeAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.context.delete(self.itemArray[indexPath.row])
                self.itemArray.remove(at: indexPath.row)
                self.tableView.reloadData()
            }

            alert.addAction(removeAction)
            alert.addAction(cancelAction)

            self.present(alert, animated: true, completion: nil)
        })

        return [deleteAction]
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
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) in print("Cancel action")})
        let addAction = UIAlertAction(title: "Add Item", style: .default) { (action) in
            print("Add action")
            if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
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
