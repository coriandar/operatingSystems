#include <stdio.h>

struct List_Item
{
	int item_num;
	struct List_Item* next;
};

int insert_after(struct List_Item* list_head, struct List_Item* insert_item, int n);
int remove_item(struct List_Item* list_head, int n);
void print_linked_list(struct List_Item* head);

void main()
{
	struct List_Item head = { 0, NULL };
	struct List_Item first = { 1, NULL };
	struct List_Item second = { 3, NULL };
	struct List_Item third = { 5, NULL };
	struct List_Item fourth = { 7, NULL };

	head.next = &first;
	first.next = &second;
	second.next = &third;
	third.next = &fourth;

	print_linked_list(&head);

	struct List_Item item_one = { 2, NULL };
	printf("Add 2 after 1: %d\n", insert_after(&head, &item_one, 1));
	print_linked_list(&head);

	struct List_Item item_two = { 4, NULL };
	printf("Add 4 after 3: %d\n", insert_after(&head, &item_two, 3));
	print_linked_list(&head);

	struct List_Item item_three = { 6, NULL };
	printf("Add 6 after 5: %d\n", insert_after(&head, &item_three, 5));
	print_linked_list(&head);

	struct List_Item item_four = { 8, NULL };
	printf("Add 8 after 8: %d\n", insert_after(&head, &item_four, 8));
	print_linked_list(&head);

	struct List_Item item_five = { 8, NULL };
	printf("Add 8 after 7: %d\n", insert_after(&head, &item_four, 7));
	print_linked_list(&head);

	printf("Remove 5: %d\n", remove_item(&head, 5));
	print_linked_list(&head);

	printf("Remove 0: %d\n", remove_item(&head, 0));
	print_linked_list(&head);

	printf("Remove 7: %d\n", remove_item(&head, 7));
	print_linked_list(&head);

	printf("Remove 8: %d\n", remove_item(&head, 8));
	print_linked_list(&head);

	printf("Remove 3: %d\n", remove_item(&head, 3));
	print_linked_list(&head);
}