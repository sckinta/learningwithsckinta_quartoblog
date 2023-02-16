buy_low_sell_high <- function(df, period = 364, cash_limit=Inf, num_per_buy=10, cash_per_buy=NULL){
    # whether each date is_wk52_high or is_wk52_low based price trend
    df <- map_dfr(
        df$date,
        function(today){
            wk52_price <- big_tech_stock_prices |> 
                filter(stock_symbol==!!stock_symbol, date <= today, date >= today - period) |> 
                summarise(
                    low_wk52 = min(low),
                    high_wk52 = max(high)
                ) |> 
                unlist()
            
            df |> 
                filter(date == today) |> 
                mutate(is_wk52_low = ifelse(low <= wk52_price['low_wk52'], T, F)) |> 
                mutate(is_wk52_high = ifelse(high >= wk52_price['high_wk52'], T, F))
        }
    )
    
    # determine transaction date and price if have unlimited money
    sell_df <- tibble(
        stock_symbol=character(),
        date = as.Date(x = integer(0), origin = "1970-01-01"),
        price = numeric()
    )
    
    df2 <- df |> 
        filter(is_wk52_low|is_wk52_high, date >= start_date) |> 
        filter(cumsum(is_wk52_low) > 0)
    
    while(nrow(df2) > 0) {
        sell_df <- bind_rows(
            sell_df,
            df2 |>
                filter(is_wk52_low | is_wk52_high, date >= start_date) |>
                filter(cumsum(is_wk52_high) == 1) |>
                select(stock_symbol, date, price = high)
        )
        
        df2 <- df2 |>
            filter(date > max(sell_df$date)) |>
            filter(cumsum(is_wk52_low) > 0)
        if (all(df2$is_wk52_low)) {
            break
        }
    }
    
    transaction_df <- df |> 
        filter(is_wk52_low, date >= start_date) |> 
        select(stock_symbol, date, price = low) |> 
        mutate(transaction = "buy") |> 
        bind_rows(
            sell_df |> 
                mutate(transaction = "sell")
        ) |> 
        arrange(date)
    
    # plot whole time price trends with transaction point
    
    big_tech_stock_prices |> 
        filter(stock_symbol==!!stock_symbol) |> 
        ggplot(aes(x = date)) +
        geom_line(aes(y = low), color = "red", alpha = 0.2) +
        geom_line(aes(y = high), color = "blue", alpha = 0.2) +
        geom_vline(aes(xintercept = start_date), color = "orange") +
        geom_point(
            data = transaction_df,
            aes(y = price, color = transaction), shape = 3)
    
    
    # determine transaction cycle
    transaction_df <- transaction_df |>
        left_join(transaction_df |>
                      filter(transaction == "sell") |>
                      mutate(cycle = row_number())) |>
        fill(cycle, .direction = "up") |>
        group_by(cycle) |>
        mutate(cycle = cur_group_id()) |>
        ungroup()
    
    # buy by same number of stock
    
    if (is.infinite(cash_limit)) {
        # cash unlimited
        
        if (!is.null(num_per_buy)) {
            buy_df <- transaction_df |>
                filter(transaction == "buy") |>
                mutate(stock_num = num_per_buy) |>
                mutate(stock_cash = -stock_num * price)
        }
        
        if (!is.null(cash_per_buy)) {
            buy_df <- transaction_df |>
                filter(transaction == "buy") |>
                mutate(stock_cash = -cash_per_buy) |>
                mutate(stock_num = -stock_cash / price)
        }
        
        
        sell_df <- transaction_df |>
            filter(transaction == "sell") |>
            left_join(buy_df |>
                          group_by(cycle) |>
                          summarise(stock_num = -floor(sum(stock_num)))) |>  # can only sell whole stocks)
            mutate(stock_cash = -price * stock_num)
        
        
        transaction_df2 <- bind_rows(buy_df,
                                     sell_df) |> arrange(date) |>
            mutate(
                stock_num_cumsum = cumsum(stock_num),
                stock_cash_cumsum = cumsum(stock_cash)
            )
    }else{
        # cash limited
        transaction_df2 <- NULL
        total_cash <- cash_limit
        
        for (i in unique(transaction_df$cycle)) {
            if (!is.null(num_per_buy)) {
                buy_df <- transaction_df |>
                    filter(transaction == "buy", cycle == i) |>
                    mutate(stock_num = num_per_buy) |>
                    mutate(stock_cash = -stock_num * price) |>
                    mutate(
                        stock_num_cumsum = cumsum(stock_num),
                        stock_cash_cumsum = cumsum(stock_cash)
                    ) |>
                    mutate(stock_cash_cumsum = total_cash + stock_cash_cumsum) |>
                    filter(cumsum(stock_cash_cumsum > 0) == row_number())
            }
            
            if (!is.null(cash_per_buy)) {
                buy_df <- transaction_df |>
                    filter(transaction == "buy", cycle == i) |>
                    mutate(stock_cash = -cash_per_buy) |>
                    mutate(stock_num = -stock_cash / price) |>
                    mutate(
                        stock_num_cumsum = cumsum(stock_num),
                        stock_cash_cumsum = cumsum(stock_cash)
                    ) |>
                    mutate(stock_cash_cumsum = total_cash + stock_cash_cumsum) |>
                    filter(cumsum(stock_cash_cumsum >= 0) == row_number())
            }
            
            
            sell_df <- transaction_df |>
                filter(transaction == "sell", cycle == i) |>
                left_join(buy_df |>
                              group_by(cycle) |>
                              summarise(stock_num = -floor(sum(stock_num)))) |>
                mutate(stock_cash = -price * stock_num)
            
            transaction_df2 <- bind_rows(
                transaction_df2,
                bind_rows(buy_df,
                          sell_df) |> arrange(date) |>
                    mutate(
                        stock_num_cumsum = cumsum(stock_num),
                        stock_cash_cumsum = total_cash + cumsum(stock_cash)
                    )
            )
            
            total_cash <-
                transaction_df2 |> slice(n()) |> pull(stock_cash_cumsum)
        }
        
    }
    transaction_df2
}