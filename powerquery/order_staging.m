let
    Source = Raw_Orders,
    #"Removed Duplicates" = Table.Distinct(Source, {"Order_ID", "Customer_ID", "Order_Date", "Product_Category", "Product_Name", "Quantity", "Unit_Price_USD", "Discount_Percent", "Payment_Method", "Shipping_City", "Country", "Order_Status", "Customer_Rating"}),
    #"Added Custom" = Table.AddColumn(#"Removed Duplicates", "Raw Date Format", each let t = Text.Trim([Order_Date]) in
if Text.Middle(t, 4, 1) = "-" then "YYYY-MM-DD"
else if Text.Middle(t, 4, 1) = "/" then "YYYY/MM/DD"
else if Text.Middle(t, 2, 1) = "-" then "MM-DD-YYYY"
else if Text.Middle(t, 2, 1) = "/" then "DD/MM/YYYY"
else "DD Mon YYYY"),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Order Date", each let t = Text.Trim([Order_Date]) in
if Text.Middle(t, 4, 1) = "-" or Text.Middle(t, 4, 1) = "/" then
 #date(Number.From(Text.Start(t, 4)), Number.From(Text.Middle(t, 5, 2)), Number.From(Text.End(t, 2)))
else if Text.Middle(t, 2, 1) = "-" then
 #date(Number.From(Text.End(t, 4)), Number.From(Text.Start(t, 2)), Number.From(Text.Middle(t, 3, 2)))
else if Text.Middle(t, 2, 1) = "/" then
 #date(Number.From(Text.End(t, 4)), Number.From(Text.Middle(t, 3, 2)), Number.From(Text.Start(t, 2)))
else
 #date(Number.From(Text.End(t, 4)),
 List.PositionOf({"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"},
Text.Middle(t, 3, 3)) + 1,
 Number.From(Text.Start(t, 2)))),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Custom1",{{"Order Date", type date}}),
    #"Removed Columns" = Table.RemoveColumns(#"Changed Type",{"Order_Date"}),
    #"Added Custom2" = Table.AddColumn(#"Removed Columns", "Payment Key", each Text.Remove(Text.Lower([Payment_Method]), {" ", ".", "_"})),
    #"Merged Queries" = Table.NestedJoin(#"Added Custom2", {"Payment Key"}, Map_Payment, {"Key"}, "Map_Payment", JoinKind.LeftOuter),
    #"Expanded Map_Payment" = Table.ExpandTableColumn(#"Merged Queries", "Map_Payment", {"Payment Method"}, {"Payment Method"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded Map_Payment",{"Payment_Method", "Payment Key"}),
    #"Added Custom3" = Table.AddColumn(#"Removed Columns1", "Country Key", each Text.Remove(Text.Upper([Country]), {" ", "."})),
    #"Merged Queries1" = Table.NestedJoin(#"Added Custom3", {"Country Key"}, Map_Country, {"Key"}, "Map_Country", JoinKind.LeftOuter),
    #"Expanded Map_Country" = Table.ExpandTableColumn(#"Merged Queries1", "Map_Country", {"Country Name"}, {"Country Name"}),
    #"Removed Columns2" = Table.RemoveColumns(#"Expanded Map_Country",{"Country Key", "Country"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns2",{{"Country Name", "Country"}}),
    #"Replaced Value" = Table.ReplaceValue(#"Renamed Columns","","Unknown",Replacer.ReplaceValue,{"Shipping_City"}),
    #"Added Custom4" = Table.AddColumn(#"Replaced Value", "Discount Missing", each if [Discount_Percent] = null or Text.Trim(Text.From([Discount_Percent])) = "" then "Yes" else "No"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom4",{{"Discount Missing", type text}, {"Discount_Percent", type text}}),
    #"Replaced Value1" = Table.ReplaceValue(#"Changed Type1","","0",Replacer.ReplaceValue,{"Discount_Percent"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Replaced Value1",{{"Quantity", Int64.Type}, {"Unit_Price_USD", type number}, {"Discount_Percent", type number}}),
    #"Divided Column" = Table.TransformColumns(#"Changed Type2", {{"Discount_Percent", each _ / 100, type number}}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Divided Column",{{"Discount_Percent", Percentage.Type}, {"Customer_Rating", type number}}),
    #"Added Custom5" = Table.AddColumn(#"Changed Type3", "Gross Amount", each [Quantity] * [Unit_Price_USD]),
    #"Changed Type4" = Table.TransformColumnTypes(#"Added Custom5",{{"Gross Amount", type number}}),
    #"Added Custom6" = Table.AddColumn(#"Changed Type4", "Net Amount", each [Quantity] * [Unit_Price_USD] * (1 -
[Discount_Percent])),
    #"Changed Type5" = Table.TransformColumnTypes(#"Added Custom6",{{"Net Amount", type number}}),
    #"Added Custom7" = Table.AddColumn(#"Changed Type5", "Delivered Sales", each if [Order_Status] = "Delivered" then [Net Amount]
else 0),
    #"Changed Type6" = Table.TransformColumnTypes(#"Added Custom7",{{"Delivered Sales", type number}}),
    #"Added Custom8" = Table.AddColumn(#"Changed Type6", "Status Group", each if [Order_Status] = "Delivered" then "Completed"
else if [Order_Status] = "Cancelled" or
[Order_Status] = "Returned" then "Lost" else "In progress"),
    #"Changed Type7" = Table.TransformColumnTypes(#"Added Custom8",{{"Status Group", type text}}),
    #"Inserted Start of Month" = Table.AddColumn(#"Changed Type7", "Start of Month", each Date.StartOfMonth([Order Date]), type date),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Start of Month", "Month Name", each Date.MonthName([Order Date]), type text),
    #"Renamed Columns1" = Table.RenameColumns(#"Inserted Month Name",{{"Start of Month", "Order Month"}}),
    #"Inserted Year" = Table.AddColumn(#"Renamed Columns1", "Year", each Date.Year([Order Date]), Int64.Type),
    #"Renamed Columns2" = Table.RenameColumns(#"Inserted Year",{{"Order_ID", "Order ID"}, {"Customer_ID", "Customer ID"}, {"Product_Category", "Category"}, {"Product_Name", "Product"}, {"Unit_Price_USD", "Unit Price (USD)"}, {"Discount_Percent", "Discount %"}, {"Shipping_City", "City"}, {"Order_Status", "Order Status"}, {"Customer_Rating", "Rating"}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns2",{"Order ID", "Customer ID", "Product", "Category", "Quantity", "Unit Price (USD)", "Discount %", "City", "Order Status", "Rating", "Raw Date Format", "Order Date", "Payment Method", "Country", "Discount Missing", "Gross Amount", "Net Amount", "Delivered Sales", "Status Group", "Order Month", "Year", "Source File"})
in
    #"Reordered Columns"