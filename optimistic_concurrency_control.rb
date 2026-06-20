class BankAccount
    attr_reader :balance
    def initialize
        @balance = 0
        @version = 1
    end

    def deposit(amount)
        current_balance = @balance
        version = @version

        sleep 0.1

        if @version == version
            @balance = current_balance + amount
            @version += 1
        else
            raise 'Another thread sneaked in'
        end
    end
end
ths = []
ba = BankAccount.new
5.times do
    ths << Thread.new do
        ba.deposit(5)
    end
end


ths.each do |t|
    t.join
end
