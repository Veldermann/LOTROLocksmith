
function tableLenght(table)
    if table ~= nil then
        counter = 0
        for _ in pairs(table) do
            counter = counter + 1
        end
        return counter
    end
    return 0
end