local util = require("aegisub.util")
local unicode = require("aegisub.unicode")

math.isInt = function(num)
    return type(num) == "number" and math.floor(num) == num
end

math.toStrings = function(...)
    local strings, args = {}, {...}
    for i=1, #args do
        strings[i] = tostring(args[i])
    end
    return unpack(strings)
end

math.round = function(num,idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

string.formatFancy = function(fmtStr,...)
    local i, args = 0, {...}
    local outStr=fmtStr:gsub("(%%[%+%- 0]*%d*.?%d*[hlLzjtI]*)([aABcedEfFgGcnNopiuAsuxX])", function(opts,type_)
        i=i+1
        if type_=="N" then
            return tonumber(string.format(opts.."f", args[i]))
        elseif type_=="B" then
            return args[i] and 1 or 0
        else
            return string.format(opts..type_, args[i])
        end
    end)
    return outStr
end

string.patternEscape = function(str)
    return str:gsub("([%%%(%)%[%]%.%*%-%+%?%$%^])","%%%1")
end

function string:split(sep)
    local sep, fields = sep or "", {}
    self:gsub(string.format("([^%s]+)", sep), function(field)
        fields[#fields+1] = field
    end)
    return fields
end

string.toNumbers = function(base, ...)
    local numbers, args = {}, {...}
    for i=1, #args do
        numbers[i] = tonumber(args[i], base)
    end
    return unpack(numbers)
end

table.arrayToSet = function(tbl)
    local set = {}
    for i=1,#tbl do
        set[tbl[i]] = true
    end
    return set
end

-- difference, union and intersection for hashtables (comparison is done on key-val pair)
table.diff = function(left, right, preferLeft)
    local diff={}
    if preferLeft then
        left, right = right, left
    end

    for key,val in pairs(right) do
        if val ~= left[key] then
            diff[key] = val
        end
    end
    return diff
end

table.diffValues = function(left, right, preferLeft)
    local diff, j = {}
    if preferLeft then
        left, right = right, left
    end
    local leftSet = table.arrayToSet(left)

    for i=1,#right do
        if not leftSet[right[i]] then
            diff[j], j = right[i], j+1
        end
    end
    return diff
end

table.union = function(left, right, preferLeft)
    if preferLeft then
        left, right = right, left
    end
    -- write entries that differ between left<->right from right
    local union = table.diff(left, right)

    -- write left entries missing from right into diff
    for key,val in pairs(left) do
        if not union[key] then
            union[key] = val
        end
    end
end

table.intersectInto = function(...)
    local tbls = {...}
    local intersection, j = tbls[1], 0
    for i=2,#tbls do
        for key,val in pairs(intersection) do
            if val~=tbls[i][key] then
                intersection[key] = nil
            elseif i==#tbls then j=j+1 end
        end
    end
    return intersection, j
end

table.intersect = function(tbl, ...)
    return table.intersectInto(util.copy(tbl), ...)
end

table.length = function(tbl) -- currently unused
    local n = 0
    for _, _ in pairs(tbl) do n = n + 1 end
    return n
end

table.isArray = function(tbl)
    return table.length(tbl)==#tbl
end

table.filter = function(tbl, callback)
    local fltTbl = {}
    for key, val in pairs(tbl) do
        if callback(val, key, tbl) then
            fltTbl[key] = val
        end
    end
    return fltTbl
end

table.find = function(tbl,findVal)
    for key,val in pairs(tbl) do
        if val==findVal then return key end
    end
end

table.first = function(tbl)
    for key,val in pairs(tbl) do
        if val and type(key)=="number" then
            return val, key
        end
    end
end

table._insert = table.insert
table.insert = function(tbl,...)
    table._insert(tbl,...)
    return tbl
end

table.join = function(...)
    local arr, arrN = {}, 0
    for _, arg in ipairs({...}) do
        for _, val in ipairs(arg) do
            arrN = arrN + 1
            arr[arrN] = val
        end
    end
    return arr
end

table.joinInto = function(arr, ...)
    local arrN, args = #arr, {...}
    for i=1,#args do
        for j=1,#args[i] do
            arrN = arrN + 1
            arr[arrN] = args[i][j]
        end
    end
    return arr, arrN
end

table.keys = function(tbl, exclude)
    local keys, keysN = {}, 0
    local excludeSet = exclude and table.arrayToSet(type(exclude)=="table" and exclude or {exclude})
    for key,_ in pairs(tbl) do
        if not (exclude and excludeSet[key]) then
            keysN = keysN + 1
            keys[keysN] = key
        end
    end
    return keys
end

table.merge = function(...)
    local tbl = {}
    for _, arg in ipairs({...}) do
        for key, val in pairs(arg) do tbl[key] = val end
    end
    return tbl
end

table.mergeInto = function(target, ...)
    local sources = {...}
    for i=1,#sources do
        for key, val in pairs(sources[i]) do target[key] = val end
    end
    return target
end

table.pluck = function(tbl, prop)
    local plucked = {}
    for i=1,#tbl do
        plucked[i] = tbl[i][prop]
    end
    return plucked
end

table.process = function(tbl1,tbl2,callback)
    local tblProc = {}
    for key,val in pairs(tbl1) do
        tbl1[key] = callback(val,tbl2[key],key,tbl1,tbl2)
    end
    return tblProc
end

table.removeRange = function(tbl, start, end_)
    local tblLen = #tbl
    end_ = end_ or tblLen

    if end_<=start then
        return {table.remove(tbl, start)}
    end

    local rmLen, removed = end_-start+1, {}
    for i=start, tblLen do
        tbl[i], removed[i-start+1] = tbl[i+rmLen], tbl[i]
    end
    return removed
end

table.reverseArray = function(tbl)
    local length, rTbl = #tbl, {}
    for i,val in ipairs(tbl) do
        rTbl[length-i+1] = val
    end
    return rTbl
end

table.trimArray = function(tbl)
    local trimmed, t = {}, 1
    for _,val in pairs(tbl) do
        trimmed[t], t = val, t+1
    end
    return trimmed
end

table.select = function(tbl,keys)
    local selected, len = {}, 0
    for i=1,#keys do
        selected[keys[i]] = tbl[keys[i]]
        if selected[keys[i]] then
            len = len + 1
        end
    end
    return selected, len
end

table.sliceArray = function(tbl, istart, iend)
    istart, iend = istart or 1, iend or #tbl
    local arr={}
    for i = istart, iend do
        arr[1+i-istart] = tbl[i]
    end
    return arr
end

table._sort = table.sort
table.sort = function(tbl,...)
    table._sort(tbl,...)
    return tbl
end

table.values = function(tbl)
    local vals, valsN = {}, 0
    for _,val in pairs(tbl) do
        valsN = valsN + 1
        vals[valsN] = val
    end
    return vals
end

unicode.reverse = function(s)
    return table.concat(table.reverseArray(unicode.toCharTable(s)))
end

unicode.sub = function(s, i, j)
    local uniChars = unicode.toCharTable(s)
    local charCnt = #uniChars

    i = (not i and 1) or (i<0 and math.max(charCnt+i+1,1)) or util.clamp(i,1,charCnt)
    j = (not j and charCnt) or (j<0 and math.max(charCnt+j+1,1)) or util.clamp(j,1,charCnt)
    return table.concat(uniChars, "", i, j)
end

unicode.toCharTable = function(s)
    local charNum, charStart, uniChars = 1, 1, {}
    while charStart <= #s do
        local charEnd = charStart + unicode.charwidth(s:sub(charStart,charStart)) - 1
        uniChars[charNum] = s:sub(charStart, charEnd)
        charStart, charNum = charEnd+1, charNum+1
    end
    return uniChars
end

util.RGB_to_HSV = function(r,g,b)
    r,g,b = util.clamp(r,0,255), util.clamp(g,0,255), util.clamp(b,0,255)
    local v = math.max(r, g, b)
    local delta = v - math.min(r, g, b)
    if delta==0 then
        return 0,0,0
    else
        local s = delta/v
        local h = 60*(r==v and (g-b)/delta or g==v and (b-r)/delta+2 or (r-g)/delta+4)
        return h>0 and h or h+360, s, v/255
    end
end

util.uuid = function()
    -- https://gist.github.com/jrus/3197011
    math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

util.getScriptInfo = function(sub)
    local infoBlockFound, scriptInfo = false, {}
    for i=1,#sub do
        if sub[i].class=="info" then
            infoBlockFound = true
            scriptInfo[sub[i].key] = sub[i].value
        elseif infoBlockFound then break end
    end
    return scriptInfo
end

returnAll = function(...) -- blame lua
    local arr, arrN = {}, 0
    for _, arg in ipairs({...}) do
        if type(arg)=="table" then
            for _, val in ipairs(arg) do
                arrN = arrN + 1
                arr[arrN] = val
            end
        else
            arrN = arrN + 1
            arr[arrN] = arg
        end
    end
    return unpack(arr)
end

function default(var, val)
    return type(var)=="nil" and val or var
end

function assertEx(cond, msg, ...)
    if not cond then
        return string.format("Error: " .. msg, ...)
    else return cond end
end