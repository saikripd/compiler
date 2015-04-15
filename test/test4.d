int a = 5, b=a+2;
//float c=6.6;
uint d;
float e=d+2;

void main()
{
    int i=11;

    switch(i)
    {
      case 1: a=a+6;
              break;
      case b: a = i+8;
      default:a = a+9;
      case 3: a += 7;
              break;
    }
}