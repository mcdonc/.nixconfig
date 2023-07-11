#include <iostream>
#include "boolector.h"

using namespace std;
int main()
{
    Btor* btor = boolector_new();
    cout << "hello from file that uses a shared library";
    boolector_delete(btor);
}
