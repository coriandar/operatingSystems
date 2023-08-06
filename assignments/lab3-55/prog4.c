/**
 * Lab3: Assignment
 * Group55: Jamie Lee, Tony Yee
 **/

// A simple linked list
#include <stdio.h>
#include "prog4.h"
#include "listfuncs.h"

void main() {
  // Create five individual items
  List_item head = {0, null};
  List_item i1 = {1, null};
  List_item i2 = {2, null};
  List_item i3 = {3, null};
  List_item i4 = {4, null};

  // new one to add
  List_item i5 = {5, null};

  // Now link them up in the order 0-1-2-3-4
  //head.next = &i1;
  //i1.next = &i2;
  //i2.next = &i3;
  //i3.next = &i4;

  // Now link them up in the order 0-3-2-4-1
  head.next = &i3;
  i3.next = &i2;
  i2.next = &i4;
  i4.next = &i1;

  // insert last
  insert_last(&head, &i5);

  // print list
  print_linked_list(&head);

  // Go through the list and print the numbers in the order of the list
 // List_item* current = &head;
 // while (current != null) {
 //   printf("%d-", current->item_num);
 //   current = current->next;
 // }
 // printf("\n");
}
