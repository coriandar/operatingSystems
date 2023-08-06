/**
 * Lab3: Assignment
 * Group55: Jamie Lee, Tony Yee
 **/

#include <stdio.h>
#include "prog4.h"

//int insert_after(List_item *list_head, List_item *insertItem, int n)
//{
//  if (head == null)
//  {
//    return 0;
//  }
//
//  // requires find
//}
//
//int remove_item()
//{
//  if (head == null)
//  {
//    return 0;
//  }
//
//  // requires find
//}




int insert_last(List_item *head, List_item *item)
{
  if (head == null)
  {
    return 0;
  }

  List_item *current = head;

  // iterate to end of linked list.
  while (current->next != null)
  {
    current = current->next;
  }

  if (current->next == null)
  {
    current->next = item;
    printf("Inserted at end of list.\n");
    return 1;
  }
}

// Go through the list and print the numbers in the order of the list
void print_linked_list(List_item *head)
{
  if (head != NULL)
  {
    printf(head->next != NULL ? "%d-" : "%d\n\n", head->item_num);

    if (head->next != NULL)
    {
      print_linked_list(head->next);
    }

  }
  //while (current != null) {
  //  printf("%d-", current->item_num);
  //  current = current->next;
  //}
  //printf("\n");
}
















