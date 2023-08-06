#include <stdio.h>
#include "prog4.h"

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


