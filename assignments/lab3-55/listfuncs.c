/**
 * Lab3: Assignment
 * Group55: Jamie Lee, Tony Yee
 **/

#include <stdio.h>
#include "prog4.h"

/**
 * Inserts a list item into a given list after the item
 * with the specified number.
 * 
 * @param list_head - head of list.
 * @param insertItem - item to be inserted.
 * @param n - specified number, which item holds.
 * 
 * @return 1 - if insertion successful.
 * @return 0 - if insertion unsuccessful, not successful if n not found.
 **/
int insert_after(List_item *list_head, List_item *insertItem, int n)
{
    if (list_head == NULL)
    {
        return 0;
    }

    if ((list_head->item_num != n) && (list_head->next != NULL))
    {
        // traverse to next item
        return insert_after(list_head->next, insertItem, n);
    }
    else if (list_head->item_num == n)
    {
        // inserts item between list_head and list_head->next
        insertItem->next = list_head->next;
        list_head->next = insertItem;
        return 1;
    }
    else
    {
        return 0;
    }
}

/**
 * Removes a list item with the specified number from list.
 * 
 * @param list_head - head of list.
 * @param n - specified number, which item holds.
 * 
 * @return 1 - if remove successful.
 * @return 0 - if remove unsuccessful, not successful if n not found.
 **/
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
            // removes link to found item
            list_head->next = list_head->next->next;
            return 1;
        }
        else
        {
            // traverse to next item
            return remove_item(list_head->next, n);
        }
    }
}

/**
 * Go through the list and print the numbers in the order of the list
 **/
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