//
//  ViewController.swift
//  ToDo
//
//  Created by Arpit Williams on 07/09/17.
//  Copyright © 2017 StarKnights. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Properties
    
    let realm = try! Realm()
    var tasks: Results<Task>?
    var saveAction: UIAlertAction?
    
    // MARK: Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Bar
        searchBar.enablesReturnKeyAutomatically = false
        
        // Segment Control
        segmentControl.addTarget(self, action: #selector(ViewController.selected(segmentControl:)), for: .valueChanged)
        
        // Table View
        tableView.tableFooterView = UIView() // Prevents display of empty rows at the end of table view
        
        loadTasks()
    }
    
    func loadTasks() {
        tasks = realm.objects(Task.self)
        updateUI()
    }
    
    func loadTasks(with filter: String) {
        tasks = realm.objects(Task.self).filter("name contains[cd] '\(filter)'")
        updateUI()
    }
    
    func updateUI() {
        if segmentControl.selectedSegmentIndex == 0{
            // Sort tasks by name
            tasks = tasks?.sorted(byKeyPath: "name", ascending: true)
        }
        else{
            // Sort tasks by date
            tasks = tasks?.sorted(byKeyPath: "createdAt", ascending: false)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func createOrUpdate(task: Task?) {
        let title = (task == nil) ? "Create" : "Update"
        let message = (task == nil) ? "New Task" : "Existing Task"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Save Action
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default) { (action) -> Void in
            if let taskName = alertController.textFields?.first?.text {
                if task == nil{
                    // Create new task
                    let newTask = Task()
                    newTask.name = taskName
                    try! self.realm.write{
                        self.realm.add(newTask)
                    }
                } else{
                    // Update existing task
                    try! self.realm.write{
                        task?.name = taskName
                    }
                }
                self.loadTasks()
            }
        }
        saveAction.isEnabled = false
        self.saveAction = saveAction
        alertController.addAction(saveAction)
        
        // Task Text Field
        alertController.addTextField { (textField) -> Void in
            textField.placeholder = "Enter task here"
            textField.addTarget(self, action: #selector(ViewController.edited(taskTextField:)), for: .editingChanged)
            
            if task != nil{ // Update textfield with old task name
                textField.text = task?.name
            }
        }
        
        // Cancel Action
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func edited(taskTextField: UITextField!) {
        saveAction?.isEnabled = (taskTextField.text?.characters.count)! > 0
    }
    
    func selected(segmentControl: UISegmentedControl!) {
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: Table View DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Returning atleast one row for adding CreateTaskCell to last row
        let rowCount = (tasks?.count ?? 0) + 1
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.row == tasks?.count ?? 0 { // CreateTaskCell Last Row
            cell = tableView.dequeueReusableCell(withIdentifier: "CreateTaskCell", for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
            
            if (tasks?.count ?? 0) > indexPath.row { // Check against index out of bound runtime expection
                if let task = tasks?[indexPath.row] {
                    if let taskLbl = cell?.viewWithTag(1) as? UILabel { // Task Label
                        taskLbl.text = task.name
                    }
                    if let dateLbl = cell?.viewWithTag(2) as? UILabel { // Date Label
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "HH:mm:ss dd-MM-yy"
                        
                        let dateString = dateFormatter.string(from: task.createdAt)
                        dateLbl.text = dateString
                    }
                }
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // Not adding delete and edit action to last row containing CreateTaskCell
        if indexPath.row == tasks?.count ?? 0 {
            return nil
        }
        
        // Delete Action
        let deleteAction = UITableViewRowAction(style: .default, title: "Remove") { (deleteAction, indexPath) -> Void in
            if (self.tasks?.count ?? 0) > indexPath.row { // Check against index out of bound runtime expection
                if let task = self.tasks?[indexPath.row] {
                    try! self.realm.write {
                        self.realm.delete(task)
                        self.loadTasks()
                    }
                }
            }
        }
        deleteAction.backgroundColor = UIColor.orange
        
        // Edit Action
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (editAction, indexPath) -> Void in
            if (self.tasks?.count ?? 0) > indexPath.row { // Check against index out of bound runtime expection
                if let task = self.tasks?[indexPath.row] {
                    self.createOrUpdate(task: task)
                }
            }
        }
        editAction.backgroundColor = UIColor.purple
        
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Disable editing CreateTaskCell
        if indexPath.row == tasks?.count ?? 0 {
            return false
        } else {
            return true
        }
    }
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create New Task when selecting CreateTaskCell
        if indexPath.row == tasks?.count ?? 0 {
            createOrUpdate(task: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: Search Bar Delege
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadTasks() // Load All tasks
        } else {
            loadTasks(with: searchText) // Load filtered tasks
        }
    }
}

