let
    Source = Folder.Files("E:\Portfolio Projects\ecommerce-data-cleaning\raw_exports"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File", each #"Transform File"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform File"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File", Table.ColumnNames(#"Transform File"(#"Sample File"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",{{"Source.Name", type text}, {"Order_ID", type text}, {"Customer_ID", type text}, {"Order_Date", type text}, {"Product_Category", type text}, {"Product_Name", type text}, {"Quantity", Int64.Type}, {"Unit_Price_USD", type number}, {"Discount_Percent", Int64.Type}, {"Payment_Method", type text}, {"Shipping_City", type text}, {"Country", type text}, {"Order_Status", type text}, {"Customer_Rating", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Source.Name", "Source File"}})
in
    #"Renamed Columns"