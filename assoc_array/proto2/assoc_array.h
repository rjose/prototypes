#ifndef ASSOC_ARRAY_H
#define ASSOC_ARRAY_H


/* ============================================================================
 * Data Structures
 */

typedef struct AssocArrayElem_ {
        union {
                char *sval;
                long lval;
                void *vval;
        } key;

        union {
                double dval;
                long lval;
                char *sval;
                void *vval;
        } val;
} AssocArrayElem;


typedef struct AssocArray_ {
        size_t capacity;
        int num_elements;
        AssocArrayElem *elements;

        int (*compare)(const void *k1, const void *k2);
        int (*destroy)(AssocArrayElem *elem);
} AssocArray;


/* ============================================================================
 * Public API
 */

int aa_init(AssocArray *array, int num_elem, 
                                int (*compare)(const void *k1, const void *k2));

void aa_free(AssocArray *array);

int aa_set_element(AssocArray *array, const AssocArrayElem *elem);

AssocArrayElem *aa_get_element(AssocArray *array, void *key);

void aa_sort_keys(AssocArray *array);


// TODO: Add functions for reducing a list of AssocArrays

#define aa_element(array, i) &(array)->elements[i]

#endif

