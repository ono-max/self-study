class BankAccount
    History = Data.define(:tx_id, :balance)
    def initialize
        @histories = [
            History.new(0, 0)
        ]
    end

    def balance_at(current_tx_id)
        result = @histories.first
        @histories.each{|h|
            if result.tx_id < h.tx_id && h.tx_id <= current_tx_id
                result = h
            end
        }
        return result.balance
    end

    def deposit(tx_id, amount)
        @histories << History.new(tx_id, amount + balance_at(tx_id))
    end
end