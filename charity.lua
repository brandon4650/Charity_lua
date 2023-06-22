local NPC_ID = 32960 -- replace with npc id you want
local totalCollected = 0 -- to show the total gathered gold from players donating through DB
local npcGold = 0
local tableName = "zz_charity_gathering"
local splitMoneyTimerId = nil

local function SplitMoney() -- code to split the money to the player that are online with the level betweeen 10>20
    local query = WorldDBQuery("SELECT SUM(GOLD) FROM "..tableName)
    if query then
        local totalGold = query:GetInt32(0)
        if totalGold > 0 then
            local players = GetPlayersInWorld()
            local playerCount = 0
            for i, player in ipairs(players) do
                if player:GetLevel() >= 10 and player:GetLevel() <= 20 and player:IsInWorld() then -- here you can change what levels you want for 10 being lowest level up to level 20
                    playerCount = playerCount + 1
                end
            end

            local goldPerPlayer = math.floor(totalGold / (playerCount * 10000))
            local remainingGold = totalGold - (goldPerPlayer * playerCount * 10000)

            for i, player in ipairs(players) do
                if player:GetLevel() >= 10 and player:GetLevel() <= 20 and player:IsInWorld() then
                    local playerGold = goldPerPlayer * 10000
                    local additionalGold = 0
                    if remainingGold > 0 then
                        additionalGold = math.min(remainingGold, 10000)
                        remainingGold = remainingGold - additionalGold
                    end
                    playerGold = playerGold + additionalGold
                    local mailSubject = "Gold Donation"
                    local mailBody = "Here is your gold from the lovely players who have donated to help you out: " .. playerGold / 10000 .. " gold."
                    SendMail(mailSubject, mailBody, player:GetGUIDLow(), player:GetGUIDLow(), 0, 0, playerGold)
                    player:SendAreaTriggerMessage("You have received " .. playerGold / 10000 .. " gold in your mail. Please check your mail to collect it.") -- notify's the player they have recieved mail from the donations
                end
            end

            print("Split " .. totalGold .. " gold among " .. playerCount .. " players.")
        end

        WorldDBExecute("DELETE FROM "..tableName)
        totalCollected = 0
        npcGold = 0
        splitMoneyTimerId = nil
    end
end

local function ConfirmDonation(playerGUID, player)
    local query = WorldDBQuery("SELECT GOLD FROM "..tableName.." WHERE GUID = "..playerGUID)
    if query then
        local goldDonated = query:GetInt32(0)
        if goldDonated >= 100000 then
            local mailSubject = "Thank you for your Donation!"
            local mailBody = "As a token of our gratitude, please accept this gift for giving new players a better start we appreciate the hospitality."
            SendMail(mailSubject, mailBody, playerGUID, playerGUID, 61, 0, 1, 0, 213630, 1)

            player:SendBroadcastMessage("Hey " .. player:GetName() .. " Check your Mailbox")
            player:SendShowMailBox(playerGUID)

            print("Sent gift to player with GUID: " .. playerGUID)
        end
    end
end

local function OnGossipHello(event, player, object)
    player:GossipClearMenu()
    player:GossipMenuAddItem(6, "|TInterface\\icons\\inv_misc_coin_02:35:35:-30:0|tDonate gold to the NPC", 0, 1)
    player:GossipMenuAddItem(1, "Show total collected|TInterface\\icons\\6or_title_garrison_storehouse:45:165:-110:-40|t", 0, 3)
    player:GossipSendMenu(1, object)
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 1 then
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "Enter amount of gold to donate:", 0, 2, 0, code)
        player:GossipSendMenu(1, object)
    elseif intid == 2 then
        local copperAmount = tonumber(code)
        local amount = copperAmount * 10000

        if amount and amount > 0 then
            if player:GetCoinage() >= amount then
                local playerGUID = player:GetGUIDLow()
                local playerName = tostring(player:GetName())

                -- Update: Select data from zz_charity_gathering table
                local Q = WorldDBQuery("SELECT * FROM "..tableName.." WHERE GUID = "..playerGUID)
                if Q then
                    repeat
                        guid, name, gold = Q:GetInt32(0), Q:GetString(1), Q:GetInt32(2)
                        local newGold = gold + amount
                        Q_update = WorldDBQuery("UPDATE "..tableName.." SET GOLD = "..newGold.." WHERE GUID = "..playerGUID)
                    until not Q:NextRow()
                else
                    -- Insert new data into zz_charity_gathering table
                    WorldDBQuery("INSERT INTO "..tableName.." (GUID, NAME, GOLD) VALUES ("..playerGUID..", '"..playerName.."', ".. amount ..")")
                end

                player:ModifyMoney(-amount)

                -- Retrieve the current total gold from the database
                local query = WorldDBQuery("SELECT SUM(GOLD) FROM "..tableName)
                if query then
                    npcGold = query:GetInt32(0)
                end

                totalCollected = totalCollected + amount

                player:SendBroadcastMessage("You donated " .. amount / 10000 .. " gold. Thank you! The Charity Collector now has " .. npcGold / 10000 .. " gold.")

                if splitMoneyTimerId == nil and totalCollected >= 50000 then
                    splitMoneyTimerId = object:RegisterEvent(SplitMoney, 20000, 1)
                end

                -- Confirm donation and send gift if applicable
                ConfirmDonation(playerGUID, player)
            else
                player:SendBroadcastMessage("You do not have enough gold to donate that amount.")
            end
        else
            player:SendBroadcastMessage("Invalid amount entered.")
        end
        player:GossipComplete()
    elseif intid == 3 then
        -- Show total collected code

        -- Retrieve the total gold collected from the database
        local query = WorldDBQuery("SELECT SUM(GOLD) FROM "..tableName)
        if query then
            totalCollected = query:GetInt32(0)
        end

        player:SendBroadcastMessage("The total gold collected so far is " .. totalCollected / 10000 .. ".")
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
