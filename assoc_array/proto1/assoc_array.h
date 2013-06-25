#ifndef ASSOC_ARRAY_H
#define ASSOC_ARRAY_H


typedef enum {
        AA_K_STRING, AA_K_VOID
} aa_key_type;


typedef enum {
        AA_V_LONG, AA_V_DOUBLE, AA_V_STRING, AA_V_VOID
} aa_val_type;

typedef struct AssocArrayKey_ {
        aa_key_type key_type;
        union {
                char *sval;
                void *vval;
        } k;
} AssocArrayKey;

typedef struct AssocArrayVal_ {
        aa_val_type val_type;
        union {
                long lval;
                double dval;
                char *sval;
                void *vval;
        } v;
} AssocArrayVal;


typedef struct AssocArrayElem_ {
        AssocArrayKey key;
        AssocArrayVal val;
} AssocArrayElem;


typedef struct AssocArray_ {
        int num_elements;
        AssocArrayElem *elements;
} AssocArray;


void aa_init(AssocArray *array);


#endif

