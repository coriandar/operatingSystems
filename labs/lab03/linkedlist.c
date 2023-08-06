// A simple linked list
#include <stdio.h>

#define null 0

struct List_item {
  int item_num;
  struct List_item* next;
};

int insert_last(struct List_item *head, struct List_item *item) 
{
  struct List_item* current = head;
  while (current != null)
  {
    current = current->next;
    if (current == null)
    {
	    current->next = item;
	    printf("Inserted at end of list.");
	    return 1;
    }
  }
  // iterate to end of linked list.
  return 0;
}


void main() {

  // Create five individual items
  struct List_item head = {0, null};
  struct List_item i1 = {1, null};
  struct List_item i2 = {2, null};
  struct List_item i3 = {3, null};
  struct List_item i4 = {4, null};

  // new one to add
  struct List_item i5 = {5, null};

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

  // Go through the list and print the numbers in the order of the list
  struct List_item* current = &head;
  while (current != null) {
    printf("%d-", current->item_num);
    current = current->next;
  }
  printf("\n");
}
