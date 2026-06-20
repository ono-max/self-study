class BankAccount
    attr_reader :balance
    def initialize
        @balance = 0
        @mutex = Mutex.new
    end

    def deposit(amount)
        @mutex.synchronize do
            current_balance = @balance

            sleep(0.1)

            @balance = current_balance + amount
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
