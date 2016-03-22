using System;
using System.Linq;

class Group01{
 static void Main(){

  var data = new[]{"ABC", "AB3", "B12", "AZV", "BAC", "B1C"};
  var groups = data.GroupBy(
	 i => new{
		 FirstLetter = i.First(),
	   SecondLetter = i.Skip(1).First()
	});
  foreach(var gr in groups)
	{
		Console.Out.WriteLine(string.Format("{0}{1} - {2}",
  		gr.Key.FirstLetter,
			gr.Key.SecondLetter,
			string.Join(",", gr)));
	}

   Console.ReadLine();
 }
}

/* Output
AB - ABC,AB3
B1 - B12,B1C
AZ - AZV
BA - BAC
*/