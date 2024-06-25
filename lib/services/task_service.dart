import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final CollectionReference taskCollection = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      task.userId = user.uid;
      await taskCollection.doc(task.id).set(task.toMap());
    } else {
      throw Exception("User not authenticated");
    }
  }

  Future<void> updateTask(Task task) async {
    await taskCollection.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await taskCollection.doc(id).delete();
  }

  Stream<List<Task>> getTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      log("task_service.dart => user : $user");
      return taskCollection.where('userId', isEqualTo: user.uid).snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>)).toList());
    } else {
      log("task_service.dart => user not authenticated");
      throw Exception("User not authenticated");
    }
  }
}

final taskService = TaskService();
