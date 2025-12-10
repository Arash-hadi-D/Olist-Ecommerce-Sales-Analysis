let
    Source = Table.NestedJoin(olist_order_items_dataset, {"order_id"}, olist_orders_dataset, {"order_id"}, "olist_orders_dataset", JoinKind.LeftOuter),
    #"Expanded olist_orders_dataset" = Table.ExpandTableColumn(Source, "olist_orders_dataset", {"customer_id", "order_status", "order_purchase_timestamp", "order_delivered_customer_date", "order_estimated_delivery_date"}, {"customer_id", "order_status", "order_purchase_timestamp", "order_delivered_customer_date", "order_estimated_delivery_date"}),
    #"Merged Queries" = Table.NestedJoin(#"Expanded olist_orders_dataset", {"product_id"}, olist_products_dataset, {"product_id"}, "olist_products_dataset", JoinKind.LeftOuter),
    #"Expanded olist_products_dataset" = Table.ExpandTableColumn(#"Merged Queries", "olist_products_dataset", {"product_category_name"}, {"product_category_name"}),
    #"Merged Queries1" = Table.NestedJoin(#"Expanded olist_products_dataset", {"customer_id"}, olist_customers_dataset, {"customer_id"}, "olist_customers_dataset", JoinKind.LeftOuter),
    #"Expanded olist_customers_dataset" = Table.ExpandTableColumn(#"Merged Queries1", "olist_customers_dataset", {"customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"}, {"customer_unique_id", "customer_zip_code_prefix", "customer_city", "customer_state"}),
    #"Merged Queries2" = Table.NestedJoin(#"Expanded olist_customers_dataset", {"customer_state"}, Tabelle1, {"state_name_abbrv"}, "Tabelle1", JoinKind.LeftOuter),
    #"Expanded Tabelle1" = Table.ExpandTableColumn(#"Merged Queries2", "Tabelle1", {"complete_state_name", "country"}, {"complete_state_name", "country"}),
    #"Inserted Year" = Table.AddColumn(#"Expanded Tabelle1", "Year", each Date.Year([order_purchase_timestamp]), Int64.Type),
    #"Inserted Month" = Table.AddColumn(#"Inserted Year", "Month", each Date.Month([order_purchase_timestamp]), Int64.Type),
    #"Added Custom" = Table.AddColumn(#"Inserted Month", "delivery_days", each Duration.TotalDays([order_delivered_customer_date] - [order_purchase_timestamp])),
    #"Merged Queries3" = Table.NestedJoin(#"Added Custom", {"product_category_name"}, product_category_name_translation, {"product_category_name"}, "product_category_name_translation", JoinKind.LeftOuter),
    #"Expanded product_category_name_translation" = Table.ExpandTableColumn(#"Merged Queries3", "product_category_name_translation", {"product_category_name_english"}, {"product_category_name_english"}),
    #"Added Custom1" = Table.AddColumn(#"Expanded product_category_name_translation", "category_group", each if [product_category_name_english] = null 
   or Text.Trim([product_category_name_english]) = "" 
then "Uncategorized"
else if List.Contains({"audio","electronics","computers","computers_accessories","tablets_printing_image","telephony","fixed_telephony","cine_photo","consoles_games","dvds_blu_ray","cds_dvds_musicals","music"}, [product_category_name_english]) then "Electronics & Technology"
else if List.Contains({"home_appliances","home_appliances_2","home_confort","home_comfort_2","small_appliances","small_appliances_home_oven_and_coffee","air_conditioning","la_cuisine"}, [product_category_name_english]) then "Home & Appliances"
else if List.Contains({"furniture_bedroom","furniture_decor","furniture_living_room","furniture_mattress_and_upholstery","kitchen_dining_laundry_garden_furniture","bed_bath_table","office_furniture","housewares"}, [product_category_name_english]) then "Furniture & Décor"
else if List.Contains({"fashio_female_clothing","fashion_male_clothing","fashion_childrens_clothes","fashion_shoes","fashion_sport","fashion_underwear_beach","fashion_bags_accessories","watches_gifts","luggage_accessories"}, [product_category_name_english]) then "Fashion & Accessories"
else if List.Contains({"health_beauty","perfumery","diapers_and_hygiene"}, [product_category_name_english]) then "Beauty & Personal Care"
else if List.Contains({"books_general_interest","books_imported","books_technical","art","arts_and_craftmanship","stationery"}, [product_category_name_english]) then "Books & Arts"
else if List.Contains({"baby","toys"}, [product_category_name_english]) then "Baby & Kids"
else if List.Contains({"sports_leisure","cool_stuff","garden_tools"}, [product_category_name_english]) then "Sports & Outdoor"
else if List.Contains({"food","food_drink","drinks"}, [product_category_name_english]) then "Food & Drinks"
else if List.Contains({"auto","construction_tools_construction","construction_tools_lights","construction_tools_safety","costruction_tools_garden","costruction_tools_tools","home_construction","signaling_and_security","pcs"}, [product_category_name_english]) then "Tools & Automotive" 
else if List.Contains({"industry_commerce_and_business","agro_industry_and_commerce","market_place"}, [product_category_name_english]) then "Office & Business"
else if [product_category_name_english] = "pet_shop" then "Pet Supplies"
else if List.Contains({"security_and_services","party_supplies","christmas_supplies","flowers","musical_instruments"}, [product_category_name_english]) then "Miscellaneous & Services"
else "Other"),
    #"Merged Queries4" = Table.NestedJoin(#"Added Custom1", {"order_id"}, olist_order_reviews_dataset, {"order_id"}, "olist_order_reviews_dataset", JoinKind.LeftOuter),
    #"Expanded olist_order_reviews_dataset" = Table.ExpandTableColumn(#"Merged Queries4", "olist_order_reviews_dataset", {"review_score"}, {"review_score"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded olist_order_reviews_dataset", each [delivery_days] < 91),
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [Year] > 2016),
    #"Filtered Rows2" = Table.SelectRows(#"Filtered Rows1", each [order_purchase_timestamp] >= #datetime(2016, 12, 31, 0, 0, 0) and [order_purchase_timestamp] <= #datetime(2018, 9, 1, 0, 0, 0))
in
    #"Filtered Rows2"