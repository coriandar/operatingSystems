#include "prog4.c"

int insert_after(struct List_Item* list_head, struct List_Item* insert_item, int n)
{
	if ((list_head->item_num != n) && (list_head->next != NULL))
	{
		return insert_after(list_head->next, insert_item, n);
	}
	else if (list_head->item_num == n)
	{
		insert_item->next = list_head->next;
		list_head->next = insert_item;

		return 1;
	}
}

int remove_item(struct List_Item* list_head, int n)
{
	if (list_head->item_num == n)
	{
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

void print_linked_list(struct List_Item* head)
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