/**
 * Lab3: Assignment
 * Group55: Jamie Lee, Tony Yee
 **/

// A simple linked list
#include <stdio.h>
#include "prog4.h"
#include "listfuncs.h"

void main() {
  List_item head = { 0, NULL };
  List_item first = { 1, NULL };
  List_item second = { 3, NULL };
  List_item third = { 5, NULL };
  List_item fourth = { 7, NULL };

  head.next = &first;
  first.next = &second;
  second.next = &third;
  third.next = &fourth;

  printf("---------------------------------------------------\n");
  printf("Current linkedlist: ");
  print_linked_list(&head);
  printf("---------------------------------------------------\n");

  printf("TESTING: insert_after\n");
  List_item item_zero = { 0, NULL };
  printf("Add 0 after 0, return code: %d\n", insert_after(&head, &item_zero, 0));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  List_item item_one = { 2, NULL };
  printf("Add 2 after 1, return code: %d\n", insert_after(&head, &item_one, 1));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  List_item item_two = { 4, NULL };
  printf("Add 4 after 3: return code: %d\n", insert_after(&head, &item_two, 3));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  List_item item_three = { 6, NULL };
  printf("Add 6 after 5: return code: %d\n", insert_after(&head, &item_three, 5));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  List_item item_four = { 8, NULL };
  printf("Add 8 after 7: return code: %d\n", insert_after(&head, &item_four, 7));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  List_item item_five = { 9, NULL };
  printf("Add 9 after 9: return code: %d\n", insert_after(&head, &item_five, 9));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("---------------------------------------------------\n");

  printf("TESTING: remove_item\n");
  printf("Remove 0: return code: %d\n", remove_item(&head, 0));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("Remove 5: return code: %d\n", remove_item(&head, 5));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("Remove 7: return code: %d\n", remove_item(&head, 7));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("Remove 8: return code: %d\n", remove_item(&head, 8));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("Remove 3: return code: %d\n", remove_item(&head, 3));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("Remove 3: return code: %d\n", remove_item(&head, 3));
  printf("Current linkedlist: ");
  print_linked_list(&head);

  printf("---------------------------------------------------\n");

  //List_item *null_head = NULL;
  //printf("TESTING: insert_after with NULL\n");

  //printf("TESTING: remove_item with NULL\n");
  //printf("Remove 0: return code: %d\n", remove_item(null_head, 0));

  //printf("---------------------------------------------------\n");
}
