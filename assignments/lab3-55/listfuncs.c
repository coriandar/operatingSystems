/**
 * Lab3: Assignment
 * Group55: Jamie Lee, Tony Yee
 **/

#include <stdio.h>
#include "prog4.h"

int insert_after(List_item *list_head, List_item *insertItem, int n)
{
  if (list_head == NULL)
  {
    return 0;
  }

  if ((list_head->item_num != n) && (list_head->next != NULL))
  {
    return insert_after(list_head->next, insertItem, n);
  }
  else if (list_head->item_num == n)
  {
    insertItem->next = list_head->next;
    list_head->next = insertItem;
    return 1;
  }
  else
  {
    return 0;
  }

}

int remove_item(List_item *list_head, int n)
{
  if (list_head == NULL)
  {
    return 0;
  }

  if (list_head->item_num == n)
  {
    // pointer to pointer
    // pointer to head needs to point to head->next
    *list_head = *list_head->next;
    return 1;
  }

  if (list_head->next != NULL)
  {
    if (list_head->next->item_num == n)
    {
      list_head->next = list_head->next->next;
      return 1;
    }
      else
    {
      return remove_item(list_head->next, n);
    }
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
}
















