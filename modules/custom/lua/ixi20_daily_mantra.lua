-----------------------------------
-- Daily server mantra for the login /servmes popup.
-- Same quote for everyone on the calendar day (server local time).
-- ASCII only so the FFXI client font does not garble attribution.
-- FileWatcher drops addOverride; assignment wrap stays live.
-- Do not return this module.
-----------------------------------
require('modules/module_utils')
require('scripts/globals/server')
-----------------------------------

local m = Module:new('ixi20_daily_mantra')

local function formatQuote(quote, name, location)
    return string.format('"%s" - %s, %s', quote, name, location)
end

local function q(quote, name, location)
    return { quote = quote, name = name, location = location }
end

-- NPC dialogue with wisdom, humor, or adventuring spirit (no shop slogans).
local npcQuotes =
{
    q('People will not trust you unless you give them something to trust.', 'Zabirego-Hajigo', 'Windurst Waters'),
    q('Hard work and perseverance put you on the map.', 'Zabirego-Hajigo', 'Windurst Waters'),
    q('Cooking is as much an art as music and painting are.', 'Kopopo', 'Windurst Waters'),
    q('Strong arms, a sense of taste, and devotion.', 'Chomojinjahl', 'Windurst Waters'),
    q('We all wear masks. To which do you submit - the mask, or the beast?', 'Zolku-Azolku', 'Windurst Waters (S)'),
    q('Do not hate, be hated. Be outspoken, but never jaded.', 'Shantotto', 'Windurst Walls'),
    q('Before being cursed by a fool, make sure he is the one who gets cursed!', 'Shantotto', 'Windurst Walls'),
    q('Fear not. The peerless Shantotto will administer a proper dispelling!', 'Shantotto', 'Windurst Walls'),
    q('Bring me what I seek, and we shall address the matter you bespeak.', 'Shantotto', 'Windurst Walls'),
    q('A potent spell or two can be the key to survival in this time of war.', 'Ezuraromazura', 'Windurst Waters (S)'),
    q('To protect the Mithra populace from all manner of threats - that is the job of us guards.', 'Rakoh-Buuma', 'Windurst Woods'),
    q('Act according to our convictions while fulfilling our promise with the Tarutaru.', 'Forine', 'Windurst Woods'),
    q('All journeys begin with faith in oneself.', 'Pyru-Copyru', 'Port Windurst'),
    q('Take a good look at what lurks inside before stepping out.', 'Pyru-Copyru', 'Port Windurst'),
    q('Just because we Tarutaru look weak, does not mean you should make light of our weapons.', 'Hohbiba-Mubiba', 'Port Windurst'),
    q('I look forward to hearing of your success.', 'Melek', 'Port Windurst'),
    q('I have no time for white-livered scum that rely on magic alone.', 'Ryan', 'Port Windurst'),
    q('There is a time to attack and a time to defend.', 'Guruna-Maguruna', 'Port Windurst'),

    q('Fiends lurk in the lands beyond, so take caution!', 'Rodaillece', 'Northern San d\'Oria'),
    q('All of Altana\'s children are welcome here.', 'Abioleget', 'Northern San d\'Oria'),
    q('Paradise is a place without fear, without death!', 'Fittesegat', 'Northern San d\'Oria'),
    q('With each sermon, I take another step closer to Paradise.', 'Prerivon', 'Northern San d\'Oria'),
    q('Stars are more beautiful up close. Don\'t you agree?', 'Bertenont', 'Northern San d\'Oria'),
    q('Is this your first time here? Join us in prayer!', 'Pellimie', 'Northern San d\'Oria'),
    q('Take your time! I can wait if it makes the job easier for you!', 'Capucine', 'Southern San d\'Oria'),
    q('Use your head. Now begone!', 'Halver', 'Southern San d\'Oria'),
    q('You have the look of a fine warrior.', 'Mieuseloir B Enchelles', 'Southern San d\'Oria (S)'),
    q('The eyes of the Goddess are ever upon us.', 'Febrenard C Brunnaut', 'Southern San d\'Oria (S)'),
    q('After years of training in the Far East, my work has only just begun.', 'Noillurie', 'Southern San d\'Oria (S)'),
    q('To avenge the souls of those lost, we must join hands and take up arms as one.', 'Feldrautte I Rouhent', 'Southern San d\'Oria (S)'),
    q('My name is Andelain. As part of my devotions, I come here each day to pray.', 'Andelain', 'East Ronfaure'),

    q('Your fate rides on the changing winds of Vana\'diel.', 'Mariadok', 'Bastok Mines'),
    q('The only things an adventurer needs are courage and a good suit of armor!', 'Deegis', 'Bastok Mines'),
    q('Do not worry. I have got your back!', 'Naji', 'Metalworks'),

    q('What matters is effort!', 'Maat', 'Ru\'Lude Gardens'),
    q('Just get out there and fight. Then you\'ll see!', 'Maat', 'Ru\'Lude Gardens'),
    q('We deal in things you cannot buy anywhere else.', 'Aldo', 'Lower Jeuno'),
    q('Love... Romance... It\'s all fake!', 'Mertaire', 'Lower Jeuno'),
    q('This tunnel leads to Qufim. Everyone is advised to stay out. Of course you adventurers never listen.', 'Cumetouflaix', 'Port Jeuno'),

    q('Remember to take your medicine in small doses.', 'Gavrie', 'Aht Urhgan Whitegate'),
    q('Sorry for all the trouble. Please ignore Hadahda the next time he asks you to do something.', 'Mushayra', 'Aht Urhgan Whitegate'),

    q('You want the path of the Samurai? Then prove you are worthy.', 'Gilgamesh', 'Norg'),
    q('Find a fine cook and your problems will be solved!', 'Komalata', 'Tavnazian Safehold'),
    q('Our people often fall prey to roving Orcs nearby. Take care out there!', 'Diadonour', 'West Ronfaure'),
    q('Ghelsba and its Orcish camps could attack at any time.', 'Chatarre', 'West Ronfaure'),
    q('If you sense danger, just flee into the city.', 'Adalefont', 'West Ronfaure'),
    q('I can\'t believe I\'ve lost my way! They must have used an Orcish spell to change the terrain!', 'Quemaricond', 'Davoi'),
}

-- Real-world wisdom (public-domain or widely attributed sayings).
local realLifeQuotes =
{
    q('The journey of a thousand miles begins with a single step.', 'Lao Tzu', 'Ancient China'),
    q('Fall seven times, stand up eight.', 'Japanese Proverb', 'Japan'),
    q('It does not matter how slowly you go as long as you do not stop.', 'Confucius', 'Ancient China'),
    q('We are what we repeatedly do.', 'Aristotle', 'Ancient Greece'),
    q('Luck is what happens when preparation meets opportunity.', 'Seneca', 'Ancient Rome'),
    q('The obstacle is the way.', 'Marcus Aurelius', 'Ancient Rome'),
    q('What you seek is seeking you.', 'Rumi', 'Persia'),
    q('Well done is better than well said.', 'Benjamin Franklin', 'Philadelphia'),
    q('Alone we can do so little; together we can do so much.', 'Helen Keller', 'United States'),
    q('Life is like riding a bicycle. To keep your balance, you must keep moving.', 'Albert Einstein', 'Germany'),
    q('The only way out is through.', 'Robert Frost', 'New England'),
    q('Do what you can, with what you have, where you are.', 'Theodore Roosevelt', 'United States'),
    q('It always seems impossible until it is done.', 'Nelson Mandela', 'South Africa'),
    q('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill', 'United Kingdom'),
    q('Nothing will work unless you do.', 'Maya Angelou', 'United States'),
    q('Be the change that you wish to see in the world.', 'Mahatma Gandhi', 'India'),
    q('Life is a journey, not a destination.', 'Ralph Waldo Emerson', 'United States'),
    q('Character is destiny.', 'Heraclitus', 'Ancient Greece'),
    q('Know yourself and know your enemy.', 'Sun Tzu', 'Ancient China'),
    q('He who has a why to live can bear almost any how.', 'Friedrich Nietzsche', 'Germany'),
    q('The wound is the place where the light enters you.', 'Rumi', 'Persia'),
    q('Patience is bitter, but its fruit is sweet.', 'Jean-Jacques Rousseau', 'France'),
    q('Act as if what you do makes a difference. It does.', 'William James', 'United States'),
    q('In the middle of difficulty lies opportunity.', 'Albert Einstein', 'Germany'),
    q('It is never too late to be what you might have been.', 'George Eliot', 'England'),
    q('Courage is not the absence of fear, but action in spite of it.', 'Mark Twain', 'United States'),
    q('The best time to plant a tree was twenty years ago. The second best time is now.', 'Chinese Proverb', 'China'),
    q('A smooth sea never made a skilled sailor.', 'English Proverb', 'England'),
    q('Fortune favors the bold.', 'Virgil', 'Ancient Rome'),
    q('Waste no more time arguing about what a good person should be. Be one.', 'Marcus Aurelius', 'Ancient Rome'),
}

local mantras = {}

for _, entry in ipairs(npcQuotes) do
    mantras[#mantras + 1] = formatQuote(entry.quote, entry.name, entry.location)
end

for _, entry in ipairs(realLifeQuotes) do
    mantras[#mantras + 1] = formatQuote(entry.quote, entry.name, entry.location)
end

local function pickDailyMantra()
    local dayKey = tonumber(os.date('%Y%m%d')) or 0
    return mantras[(dayKey % #mantras) + 1]
end

-- Any language: the client may ask for English (2) or French (4).
-- Returning empty for the second request blanks the welcome body.
local function serverMessage(language, fallback)
    if #mantras > 0 then
        return pickDailyMantra()
    end

    if fallback then
        return fallback(language)
    end

    return ''
end

m:addOverride('xi.server.getServerMessage', function(language)
    return serverMessage(language, super)
end)

-- FileWatcher drops addOverride; assignment wrap stays live.
if not xi.server._ixi20DailyMantra then
    xi.server._ixi20DailyMantra = true

    local previous = xi.server.getServerMessage
    xi.server.getServerMessage = function(language)
        return serverMessage(language, previous)
    end
end

-- Stock getServerMessage reads this when the override is not applied.
if xi.settings and xi.settings.main then
    xi.settings.main.SERVER_MESSAGE = pickDailyMantra()
end
