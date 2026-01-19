class UI::Account::BalanceReconciliation < ApplicationComponent
  attr_reader :balance, :account

  def initialize(balance:, account:)
    @balance = balance
    @account = account
  end

  def reconciliation_items
    case account.accountable_type
    when "Depository", "OtherAsset", "OtherLiability"
      default_items
    when "CreditCard"
      credit_card_items
    when "Investment"
      investment_items
    when "Loan"
      loan_items
    when "Property", "Vehicle"
      asset_items
    when "Crypto"
      crypto_items
    else
      default_items
    end
  end

  private

    def default_items
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_balance"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.start_balance"), style: :start },
        { label: t("accounts.balance_reconciliation.labels.net_cash_flow"), value: net_cash_flow, tooltip: t("accounts.balance_reconciliation.tooltips.net_cash_flow"), style: :flow }
      ]

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_balance"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.end_balance"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: total_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_balance"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.final_balance"), style: :final }
      items
    end

    def credit_card_items
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_balance"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.credit_card_start_balance"), style: :start },
        { label: t("accounts.balance_reconciliation.labels.charges"), value: balance.cash_outflows_money, tooltip: t("accounts.balance_reconciliation.tooltips.charges"), style: :flow },
        { label: t("accounts.balance_reconciliation.labels.payments"), value: balance.cash_inflows_money * -1, tooltip: t("accounts.balance_reconciliation.tooltips.payments"), style: :flow }
      ]

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_balance"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.end_balance"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: total_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_balance"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.credit_card_final_balance"), style: :final }
      items
    end

    def investment_items
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_balance"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.investment_start_balance"), style: :start }
      ]

      # Change in brokerage cash (includes deposits, withdrawals, and cash from trades)
      items << { label: t("accounts.balance_reconciliation.labels.change_in_brokerage_cash"), value: net_cash_flow, tooltip: t("accounts.balance_reconciliation.tooltips.change_in_brokerage_cash"), style: :flow }

      # Change in holdings from trading activity
      items << { label: t("accounts.balance_reconciliation.labels.change_in_holdings_trades"), value: net_non_cash_flow, tooltip: t("accounts.balance_reconciliation.tooltips.change_in_holdings_trades"), style: :flow }

      # Market price changes
      items << { label: t("accounts.balance_reconciliation.labels.change_in_holdings_market"), value: balance.net_market_flows_money, tooltip: t("accounts.balance_reconciliation.tooltips.change_in_holdings_market"), style: :flow }

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_balance"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.investment_end_balance"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: total_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_balance"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.investment_final_balance"), style: :final }
      items
    end

    def loan_items
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_principal"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.start_principal"), style: :start },
        { label: t("accounts.balance_reconciliation.labels.net_principal_change"), value: net_non_cash_flow, tooltip: t("accounts.balance_reconciliation.tooltips.net_principal_change"), style: :flow }
      ]

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_principal"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.end_principal"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: balance.non_cash_adjustments_money, tooltip: t("accounts.balance_reconciliation.tooltips.adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_principal"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.final_principal"), style: :final }
      items
    end

    def asset_items # Property/Vehicle
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_value"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.start_value"), style: :start },
        { label: t("accounts.balance_reconciliation.labels.net_value_change"), value: net_total_flow, tooltip: t("accounts.balance_reconciliation.tooltips.net_value_change"), style: :flow }
      ]

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_value"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.end_value"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: total_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.asset_adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_value"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.final_value"), style: :final }
      items
    end

    def crypto_items
      items = [
        { label: t("accounts.balance_reconciliation.labels.start_balance"), value: balance.start_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.crypto_start_balance"), style: :start }
      ]

      items << { label: t("accounts.balance_reconciliation.labels.buys"), value: balance.cash_outflows_money * -1, tooltip: t("accounts.balance_reconciliation.tooltips.buys"), style: :flow } if balance.cash_outflows != 0
      items << { label: t("accounts.balance_reconciliation.labels.sells"), value: balance.cash_inflows_money, tooltip: t("accounts.balance_reconciliation.tooltips.sells"), style: :flow } if balance.cash_inflows != 0
      items << { label: t("accounts.balance_reconciliation.labels.market_changes"), value: balance.net_market_flows_money, tooltip: t("accounts.balance_reconciliation.tooltips.market_changes"), style: :flow } if balance.net_market_flows != 0

      if has_adjustments?
        items << { label: t("accounts.balance_reconciliation.labels.end_balance"), value: end_balance_before_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.investment_end_balance"), style: :subtotal }
        items << { label: t("accounts.balance_reconciliation.labels.adjustments"), value: total_adjustments, tooltip: t("accounts.balance_reconciliation.tooltips.adjustments"), style: :adjustment }
      end

      items << { label: t("accounts.balance_reconciliation.labels.final_balance"), value: balance.end_balance_money, tooltip: t("accounts.balance_reconciliation.tooltips.crypto_final_balance"), style: :final }
      items
    end

    def net_cash_flow
      balance.cash_inflows_money - balance.cash_outflows_money
    end

    def net_non_cash_flow
      balance.non_cash_inflows_money - balance.non_cash_outflows_money
    end

    def net_total_flow
      net_cash_flow + net_non_cash_flow + balance.net_market_flows_money
    end

    def total_adjustments
      balance.cash_adjustments_money + balance.non_cash_adjustments_money
    end

    def has_adjustments?
      balance.cash_adjustments != 0 || balance.non_cash_adjustments != 0
    end

    def end_balance_before_adjustments
      balance.end_balance_money - total_adjustments
    end
end
