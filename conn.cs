using System;
using System.Linq;

class Conn01{
 static void Main(){

 string connString = @"Data Source=(LocalDB)\MSSQLLocalDB;";
 connString += @"AttachDbFilename=C:\proj\db\SportsStore.mdf";
 connString += "Integrated Security=True; Connect Timeout = 30";
				
 using (SqlConnection connection = new SqlConnection(connectionString)) {    
	connection.Open();
	var myCommand = new SqlCommand("select * from products");
	myCommand.Connection = connection;
	using (var reader = myCommand.ExecuteReader()) {
		while (reader.Read())
			Console.WriteLine(myReader.GetValue(1));
	}
 }
 Console.ReadLine();
 }
}