//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    // потушить выделение ячейки
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
 
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: task) {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let text = indexPath.section == 0 ? "Done" : "Not Done"
        let color = indexPath.section == 0 ? #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) : #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        
        let doneAction = UIContextualAction(style: .normal, title: text) { _, _, isDone in
            StorageManager.shared.done(task: task)
            
            // определяем индекс в текущих или выполненных задачах
            let indexPathForCurrentTask = IndexPath(
                row: self.currentTasks.index(of: task) ?? 0,
                section: 0
            )
            let indexPathForCompletedTask = IndexPath(
                row: self.completedTasks.index(of: task) ?? 0,
                section: 1
            )
            
            // определяем индекс назначения
            let destinationIndexRow = indexPath.section == 0
            ? indexPathForCompletedTask
            : indexPathForCurrentTask
            
            // перемещаем строку
            tableView.moveRow(at: indexPath, to: destinationIndexRow)
            isDone(true)
        }
        
        doneAction.backgroundColor = color
        editAction.backgroundColor = .orange
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let title = task != nil ? "Edit Task" : "New Task"
        
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        alert.action(with: task) { newValue, note in
            if let task = task, let completion = completion {
                StorageManager.shared.edit(task, newName: newValue, newNote: note)
                completion()
            } else {
                self.saveTask(withName: newValue, andNote: note)
            }
        }
        present(alert, animated: true)
    }
    
    private func saveTask(withName name: String, andNote note: String) {
        let task = Task(value: [name, note])
        StorageManager.shared.save(task, to: taskList)
        
        let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}
