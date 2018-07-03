typedef struct list
{
    char name[10];
    int posn;
    struct list* next;
}ARGLIST;

typedef struct node
{
    char name[20];
    int pos;
    struct node* next;
}NAMTAB;

typedef struct node1
{
    int pos, num_of_arg;
    ARGLIST * arg;
    char array[300];
    struct node1* next;
}DEFTAB;

typedef struct node2
{
    char args[20];
    struct node2* next;
}ARGTAB;
