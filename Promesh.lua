--[[
    ================================================================
    [EXYT3 VIRTUAL MACHINE ENGINE]
    Protected & Virtualized by guivmz
    All Rights Reserved
    ================================================================
]]

return (function(...)
    local _9fi24g = (getgenv and getgenv()) or (getfenv and getfenv()) or _ENV or _G
    local StringChar = string.char
    local StringByte = string.byte
    local StringSub = string.sub
    local TableConcat = table.concat
    local TableInsert = table.insert
    local MathFloor = math.floor
    local Pcall = pcall
    local Unpack = unpack or table.unpack
    local RawSet = rawset

    -- Bitwise XOR with math fallback
    local BitXor = (bit32 and bit32.bxor) or (bit and bit.bxor) or function(a, b)
        local p, c = 1, 0
        while a > 0 and b > 0 do
            local ra, rb = a % 2, b % 2
            if ra ~= rb then c = c + p end
            a, b, p = MathFloor(a / 2), MathFloor(b / 2), p * 2
        end
        if a > 0 then c = c + a * p end
        if b > 0 then c = c + b * p end
        return c
    end

    -- Pack helper ensuring accurate return count even with nil values
    local function packRet(...)
        return select('#', ...), { ... }
    end

    local function safeIndex(t, k)
        return t[k]
    end

    local function safeNewIndex(t, k, v)
        t[k] = v
    end

    local _fcg9v9 = 147
    local _401cfj = "ACAAAAABAQAAXwAAAAAAAAAAAAAAAAAADgIAAAAAAAAAAAAAAAAAXwMAAAAAAAEAAAAAAAAAGwEAAgADAAAAAAAAAAAADgMAAAAAAAAAAAAAAAAAXwQAAAAAAAIAAAAAAAAAGwIAAwAEAAAAAAAAAAAAXwMAAAAAAAMAAAAAAAAALwUAAAAAAAQAAAAAAAAAUgQABQAFAAAAAAAAAAAAXwYAAAAAAAYAAAAAAAAAxgQAAwACAAAAAAAAAAAALwYAAAAAAAQAAAAAAAAAUgUABgAFAAAAAAAAAAAAXwcAAAAAAAcAAAAAAAAAxgUAAwACAAAAAAAAAAAALwYAAAAAAAgAAAAAAAAALwgAAAAAAAQAAAAAAAAAXwkAAAAAAAkAAAAAAAAASQcACAAJAAAAAAAAAAAAxgYAAgACAAAAAAAAAAAAXwcAAAAAAAoAAAAAAAAALwgAAAAAAAsAAAAAAAAAcgkAAAAAAAAAAAAAAAAAxggAAgABAAAAAAAAAAAAXwgAAAAAAAoAAAAAAAAALwkAAAAAAAsAAAAAAAAAcgoAAAAAAAEAAAAAAAAAxgkAAgABAAAAAAAAAAAALwsAAAAAAAwAAAAAAAAADgwACAAAAAAAAAAAAAAAxgsAAgACAAAAAAAAAAAAXwwAAAAAAA0AAAAAAAAA9AAACwAMAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALgoAAAABAAAAAAAAAAAALgoAAQAAAAAAAAAAAAAAYQkACgABAAAAAAAAAAAAEgAAAAAAAAAAAAAHAAAADg0ACAAAAAAAAAAAAAAAHgsADQAAAAAAAAAAAAAAXwwAAAAAAA4AAAAAAAAAVQEACwAMAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALgkAAAABAAAAAAAAAAAALgkAAQAAAAAAAAAAAAAAbQkAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAGAAAALwkAAAAAAA8AAAAAAAAAXwoAAAAAABAAAAAAAAAAxgkAAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfAkAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAAAcgkAAAAAAAIAAAAAAAAAcgoAAAAAAAMAAAAAAAAADgsACgAAAAAAAAAAAAAADgwAAQAAAAAAAAAAAAAAdw0AAAAAAAAAAAAAAAAAXw4AAAAAABEAAAAAAAAADg8ABgAAAAAAAAAAAAAApw0ADgAPAAAAAAAAAAAAXw4AAAAAABIAAAAAAAAADg8ABwAAAAAAAAAAAAAApw0ADgAPAAAAAAAAAAAAXw4AAAAAABMAAAAAAAAADg8ACAAAAAAAAAAAAAAApw0ADgAPAAAAAAAAAAAAXw4AAAAAABQAAAAAAAAALw8AAAAAAAgAAAAAAAAALxEAAAAAABUAAAAAAAAAXxIAAAAAABYAAAAAAAAASRAAEQASAAAAAAAAAAAAxhAAAQAAAAAAAAAAAAAAxg8AAAACAAAAAAAAAAAApw0ADgAPAAAAAAAAAAAAxgsAAwACAAAAAAAAAAAADg4ACwAAAAAAAAAAAAAAew0ADgAAAAAAAAAAAAAAYQwADQABAAAAAAAAAAAAEgAAAAAAAAAAAAAIAAAADhAACwAAAAAAAAAAAAAAXxEAAAAAABcAAAAAAAAASQ4AEAARAAAAAAAAAAAAXw8AAAAAABgAAAAAAAAA9AAADgAPAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALgwAAAABAAAAAAAAAAAALgwAAQAAAAAAAAAAAAAAbQwAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAPAAAALwwAAAAAAA8AAAAAAAAAXw4AAAAAABkAAAAAAAAALw8AAAAAAAgAAAAAAAAADhEACwAAAAAAAAAAAAAAYRAAEQAAAAAAAAAAAAAAEgAAAAAAAAAAAAADAAAADhIACwAAAAAAAAAAAAAAXxMAAAAAABcAAAAAAAAASRAAEgATAAAAAAAAAAAAxg8AAgACAAAAAAAAAAAAGw0ADgAPAAAAAAAAAAAAxgwAAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfAwAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAAArAwADAAAAAAAAAAAAAAALw0AAAAAAAsAAAAAAAAAcg4AAAAAAAQAAAAAAAAAxg0AAgACAAAAAAAAAAAADhEADQAAAAAAAAAAAAAAexAAEQAAAAAAAAAAAAAAYQ8AEAABAAAAAAAAAAAAEgAAAAAAAAAAAAACAAAADhEADAAAAAAAAAAAAAAAew8AEQAAAAAAAAAAAAAAYQ4ADwABAAAAAAAAAAAAEgAAAAAAAAAAAAAEAAAADhEADAAAAAAAAAAAAAAAXxIAAAAAABoAAAAAAAAASRAAEQASAAAAAAAAAAAAew4AEAAAAAAAAAAAAAAAbQ4AAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAANAAAALw4AAAAAAA8AAAAAAAAAXxAAAAAAABsAAAAAAAAADhMACwAAAAAAAAAAAAAAXxQAAAAAABwAAAAAAAAASRIAEwAUAAAAAAAAAAAAYREAEgABAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAAXxEAAAAAAB0AAAAAAAAAGw8AEAARAAAAAAAAAAAAxg4AAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfA4AAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAAADg8ADAAAAAAAAAAAAAAAXxAAAAAAABoAAAAAAAAASQ4ADwAQAAAAAAAAAAAALxAAAAAAAB4AAAAAAAAAXxEAAAAAAB8AAAAAAAAASQ8AEAARAAAAAAAAAAAAXxAAAAAAACAAAAAAAAAAxg8AAgABAAAAAAAAAAAADg8ACgAAAAAAAAAAAAAADhAAAgAAAAAAAAAAAAAAdxEAAAAAAAAAAAAAAAAAXxIAAAAAABoAAAAAAAAADhMADgAAAAAAAAAAAAAApxEAEgATAAAAAAAAAAAAXxIAAAAAABMAAAAAAAAADhMACAAAAAAAAAAAAAAApxEAEgATAAAAAAAAAAAAXxIAAAAAABEAAAAAAAAADhMABgAAAAAAAAAAAAAApxEAEgATAAAAAAAAAAAAXxIAAAAAABQAAAAAAAAALxMAAAAAAAgAAAAAAAAALxUAAAAAABUAAAAAAAAAXxYAAAAAABYAAAAAAAAASRQAFQAWAAAAAAAAAAAAxhQAAQAAAAAAAAAAAAAAxhMAAAACAAAAAAAAAAAApxEAEgATAAAAAAAAAAAAxg8AAwACAAAAAAAAAAAADhIADwAAAAAAAAAAAAAAexEAEgAAAAAAAAAAAAAAYRAAEQABAAAAAAAAAAAAEgAAAAAAAAAAAAAIAAAADhQADwAAAAAAAAAAAAAAXxUAAAAAABcAAAAAAAAASRIAFAAVAAAAAAAAAAAAXxMAAAAAABgAAAAAAAAA9AAAEgATAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALhAAAAABAAAAAAAAAAAALhAAAQAAAAAAAAAAAAAAbRAAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAPAAAALxAAAAAAAA8AAAAAAAAAXxIAAAAAACEAAAAAAAAALxMAAAAAAAgAAAAAAAAADhUADwAAAAAAAAAAAAAAYRQAFQAAAAAAAAAAAAAAEgAAAAAAAAAAAAADAAAADhYADwAAAAAAAAAAAAAAXxcAAAAAABcAAAAAAAAASRQAFgAXAAAAAAAAAAAAxhMAAgACAAAAAAAAAAAAGxEAEgATAAAAAAAAAAAAxhAAAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfBAAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAAADhEADwAAAAAAAAAAAAAAXxIAAAAAABwAAAAAAAAASRAAEQASAAAAAAAAAAAALxMAAAAAAAwAAAAAAAAADhQAEAAAAAAAAAAAAAAAxhMAAgACAAAAAAAAAAAAXxQAAAAAAA0AAAAAAAAA9AAAEwAUAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALhIAAAABAAAAAAAAAAAALhIAAQAAAAAAAAAAAAAAYREAEgABAAAAAAAAAAAAEgAAAAAAAAAAAAAHAAAADhUAEAAAAAAAAAAAAAAAHhMAFQAAAAAAAAAAAAAAXxQAAAAAACIAAAAAAAAAVQEAEwAUAAAAAAAAAAAAEgAAAAAAAAAAAAABAAAALhEAAAABAAAAAAAAAAAALhEAAQAAAAAAAAAAAAAAbREAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAGAAAALxEAAAAAAA8AAAAAAAAAXxIAAAAAACMAAAAAAAAAxhEAAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfBEAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAAAAAALxEAAAAAACQAAAAAAAAADhIAEAAAAAAAAAAAAAAAxhEAAgADAAAAAAAAAAAADhQAEQAAAAAAAAAAAAAAexMAFAAAAAAAAAAAAAAAbRMAAAAAAAAAAAAAAAAAEgAAAAAAAAAAAAAKAAAALxMAAAAAAA8AAAAAAAAAXxUAAAAAACUAAAAAAAAALxYAAAAAAAgAAAAAAAAADhcAEgAAAAAAAAAAAAAAxhYAAgACAAAAAAAAAAAAGxQAFQAWAAAAAAAAAAAAxhMAAgABAAAAAAAAAAAABAAAAQAAAAAAAAAAAAAAfBMAAAAAAAAAAAAAAAAAEgAAAAAA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"

    -- Fast Base64 decoder with byte mapping, buffer masking and chunked concatenation
    local function unpackB64(s)
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        local map = {}
        for i = 1, 64 do
            map[StringByte(b, i)] = i - 1
        end
        local chunks = {}
        local chunk = {}
        local chunkIdx = 1
        local buffer = 0
        local bits = 0
        local sLen = #s
        for i = 1, sLen do
            local code = StringByte(s, i)
            local val = map[code]
            if val then
                buffer = buffer * 64 + val
                bits = bits + 6
                if bits >= 8 then
                    bits = bits - 8
                    local byte = MathFloor(buffer / (2 ^ bits)) % 256
                    buffer = buffer % (2 ^ bits)
                    chunk[chunkIdx] = StringChar(byte)
                    chunkIdx = chunkIdx + 1
                    if chunkIdx > 4096 then
                        chunks[#chunks + 1] = TableConcat(chunk)
                        chunk = {}
                        chunkIdx = 1
                    end
                end
            end
        end
        if chunkIdx > 1 then
            chunks[#chunks + 1] = TableConcat(chunk)
        end
        return TableConcat(chunks)
    end

    local _bwjhs9 = unpackB64(_401cfj)
    local pos = 1

    local function readByte()
        local b = StringByte(_bwjhs9, pos)
        pos = pos + 1
        return b or 0
    end

    local function readInt16()
        local b1, b2 = StringByte(_bwjhs9, pos, pos + 1)
        pos = pos + 2
        return (b1 or 0) + (b2 or 0) * 256
    end

    local function readInt32()
        local b1, b2, b3, b4 = StringByte(_bwjhs9, pos, pos + 3)
        pos = pos + 4
        return (b1 or 0) + (b2 or 0) * 256 + (b3 or 0) * 65536 + (b4 or 0) * 16777216
    end

    local function readSignedInt32()
        local v = readInt32()
        if v >= 2147483648 then
            v = v - 4294967296
        end
        return v
    end

    local function readDouble()
        local b1, b2, b3, b4, b5, b6, b7, b8 = StringByte(_bwjhs9, pos, pos + 7)
        pos = pos + 8
        b1, b2, b3, b4, b5, b6, b7, b8 = b1 or 0, b2 or 0, b3 or 0, b4 or 0, b5 or 0, b6 or 0, b7 or 0, b8 or 0
        local sign = (b8 >= 128) and -1 or 1
        local exp = (b8 % 128) * 16 + MathFloor(b7 / 16)
        local mant = ((b7 % 16) * 65536 + b6 * 256 + b5) * 4294967296 + (b4 * 16777216 + b3 * 65536 + b2 * 256 + b1)
        if exp == 0 then
            if mant == 0 then return sign * 0 end
            return sign * (mant / 4503599627370496) * (2 ^ -1022)
        elseif exp == 2047 then
            return (mant == 0) and (sign * (1/0)) or (0/0)
        else
            return sign * (1 + mant / 4503599627370496) * (2 ^ (exp - 1023))
        end
    end

    local function readString()
        local len = readInt32()
        if len <= 0 then return "" end
        local raw = StringSub(_bwjhs9, pos, pos + len - 1)
        pos = pos + len
        local chars = {}
        local chunks = {}
        local cIdx = 1
        for i = 1, len do
            chars[cIdx] = StringChar(BitXor(StringByte(raw, i), _fcg9v9) % 256)
            cIdx = cIdx + 1
            if cIdx > 4096 then
                chunks[#chunks + 1] = TableConcat(chars)
                chars = {}
                cIdx = 1
            end
        end
        if cIdx > 1 then
            chunks[#chunks + 1] = TableConcat(chars)
        end
        return TableConcat(chunks)
    end

    local function deserializeChunk()
        local np = readByte()
        local maxStack = readInt16()

        local numUpvals = readInt16()
        local u = {}
        for i = 1, numUpvals do
            u[i] = { readByte(), readInt16() }
        end

        local numInst = readInt32()
        local insts = {}
        for i = 1, numInst do
            insts[i] = {
                readByte(),
                readInt16(),
                readInt16(),
                readInt16(),
                readInt32(),
                readSignedInt32()
            }
        end

        local numConst = readInt32()
        local k = {}
        for i = 1, numConst do
            local tag = readByte()
            if tag == 0 then
                k[i] = nil
            elseif tag == 1 then
                k[i] = false
            elseif tag == 2 then
                k[i] = true
            elseif tag == 3 then
                k[i] = readDouble()
            elseif tag == 4 then
                k[i] = readString()
            end
        end

        local numProtos = readInt16()
        local p = {}
        for i = 1, numProtos do
            p[i] = deserializeChunk()
        end

        return {
            i = insts,
            k = k,
            p = p,
            s = maxStack,
            np = np,
            u = u
        }
    end

    local rootChunk = deserializeChunk()

    -- Virtual Machine Execution Engine
    local function _cqmrqj(_cxpt2g, varargs, env, upvals)
        local _8huvc6 = {}
        local openUpvalues = {}
        local topReg = _cxpt2g.s or 32

        local function getReg(r)
            local uv = openUpvalues[r]
            if uv then return uv[1] end
            return _8huvc6[r]
        end

        local function setReg(r, val)
            _8huvc6[r] = val
            local uv = openUpvalues[r]
            if uv then uv[1] = val end
        end

        local numParams = _cxpt2g.np or 0
        if varargs then
            local nArgs = varargs.n or #varargs
            local limit = numParams
            if limit > nArgs then limit = nArgs end
            for i = 1, limit do
                setReg(i - 1, varargs[i])
            end
        end

        local _cisl9b = _cxpt2g.k
        local _35rz0g = _cxpt2g.i
        local _f9f2xs = _cxpt2g.p
        local _2b7rgh = 1
        local numInst = #_35rz0g

        while _2b7rgh <= numInst do
            local _e75uhi = _35rz0g[_2b7rgh]
            local op = _e75uhi[1]
            local a = _e75uhi[2]
            local b = _e75uhi[3]
            local c = _e75uhi[4]
            local bx = _e75uhi[5]
            local sbx = _e75uhi[6]

            if op == 14 then
                setReg(a, getReg(b))
            elseif op == 95 then
                setReg(a, _cisl9b[bx + 1])
            elseif op == 46 then
                setReg(a, b == 1)
                if c == 1 then
                    _2b7rgh = _2b7rgh + 1
                end
            elseif op == 172 then
                for i = a, b do setReg(i, nil) end
            elseif op == 55 then
                local uv = upvals and upvals[b + 1]
                setReg(a, uv and uv[1])
            elseif op == 31 then
                local uv = upvals and upvals[b + 1]
                if uv then
                    uv[1] = getReg(a)
                end
            elseif op == 47 then
                local gname = _cisl9b[bx + 1]
                setReg(a, env[gname])
            elseif op == 176 then
                local gname = _cisl9b[bx + 1]
                env[gname] = getReg(a)
            elseif op == 73 then
                local tbl = getReg(b)
                local keyVal = getReg(c)
                if tbl ~= nil then
                    local ok, res = Pcall(safeIndex, tbl, keyVal)
                    if ok then
                        setReg(a, res)
                    else
                        setReg(a, nil)
                    end
                else
                    setReg(a, nil)
                end
            elseif op == 167 then
                local tbl = getReg(a)
                if tbl ~= nil then
                    Pcall(safeNewIndex, tbl, getReg(b), getReg(c))
                end
            elseif op == 119 then
                setReg(a, {})
            elseif op == 82 then
                local obj = getReg(b)
                setReg(a + 1, obj)
                local mName = _cisl9b[c + 1]
                if obj ~= nil then
                    local ok, res = Pcall(safeIndex, obj, mName)
                    setReg(a, ok and res or nil)
                else
                    setReg(a, nil)
                end
            elseif op == 96 then
                setReg(a, getReg(b) + getReg(c))
            elseif op == 143 then
                setReg(a, getReg(b) - getReg(c))
            elseif op == 130 then
                setReg(a, getReg(b) * getReg(c))
            elseif op == 208 then
                setReg(a, getReg(b) / getReg(c))
            elseif op == 116 then
                setReg(a, getReg(b) % getReg(c))
            elseif op == 65 then
                setReg(a, getReg(b) ^ getReg(c))
            elseif op == 27 then
                local v1 = getReg(b)
                local v2 = getReg(c)
                local ok, res = Pcall(function() return v1 .. v2 end)
                if ok then
                    setReg(a, res)
                else
                    setReg(a, tostring(v1 ~= nil and v1 or "") .. tostring(v2 ~= nil and v2 or ""))
                end
            elseif op == 156 then
                setReg(a, -getReg(b))
            elseif op == 123 then
                setReg(a, not getReg(b))
            elseif op == 30 then
                local val = getReg(b)
                local ok, len = Pcall(function() return #val end)
                setReg(a, ok and len or 0)
            elseif op == 18 then
                _2b7rgh = _2b7rgh + sbx
            elseif op == 244 then
                if (getReg(b) == getReg(c)) ~= (a == 1) then
                    _2b7rgh = _2b7rgh + 1
                end
            elseif op == 85 then
                if (getReg(b) < getReg(c)) ~= (a == 1) then
                    _2b7rgh = _2b7rgh + 1
                end
            elseif op == 250 then
                if (getReg(b) <= getReg(c)) ~= (a == 1) then
                    _2b7rgh = _2b7rgh + 1
                end
            elseif op == 109 then
                if (not getReg(a)) == (b == 1) then
                    _2b7rgh = _2b7rgh + 1
                end
            elseif op == 97 then
                if (not getReg(b)) == (c == 1) then
                    _2b7rgh = _2b7rgh + 1
                else
                    setReg(a, getReg(b))
                end
            elseif op == 198 then
                local fn = getReg(a)
                local args = {}
                local numArgs = 0
                if b > 1 then
                    numArgs = b - 1
                    for i = 1, numArgs do
                        args[i] = getReg(a + i)
                    end
                elseif b == 0 then
                    for i = a + 1, topReg do
                        numArgs = numArgs + 1
                        args[numArgs] = getReg(i)
                    end
                end
                local isCallable = type(fn) == "function" or (type(fn) == "table" and getmetatable(fn) and getmetatable(fn).__call)
                if isCallable then
                    local ok, nRet, results = Pcall(function()
                        return packRet(fn(Unpack(args, 1, numArgs)))
                    end)
                    if ok then
                        if c == 1 then
                            -- c=1: void call, discard all return values
                        elseif c > 1 then
                            for i = 1, c - 1 do
                                setReg(a + i - 1, results[i])
                            end
                        elseif c == 0 then
                            for i = 1, nRet do
                                setReg(a + i - 1, results[i])
                            end
                            topReg = a + nRet - 1
                        end
                    else
                        if c > 1 then
                            for i = 1, c - 1 do setReg(a + i - 1, nil) end
                        end
                    end
                else
                    if c > 1 then
                        for i = 1, c - 1 do setReg(a + i - 1, nil) end
                    end
                end
            elseif op == 4 then
                if b == 1 then
                    return
                elseif b > 1 then
                    local retList = {}
                    for i = 1, b - 1 do
                        retList[i] = getReg(a + i - 1)
                    end
                    return Unpack(retList, 1, b - 1)
                elseif b == 0 then
                    local retList = {}
                    local count = 0
                    for i = a, topReg do
                        count = count + 1
                        retList[count] = getReg(i)
                    end
                    return Unpack(retList, 1, count)
                end
            elseif op == 51 then
                setReg(a, getReg(a) - getReg(a + 2))
                _2b7rgh = _2b7rgh + sbx
            elseif op == 44 then
                local step = getReg(a + 2)
                local curr = getReg(a) + step
                setReg(a, curr)
                local limit = getReg(a + 1)
                if (step > 0 and curr <= limit) or (step <= 0 and curr >= limit) then
                    _2b7rgh = _2b7rgh + sbx
                    setReg(a + 3, curr)
                end
            elseif op == 240 then
                local iter = getReg(a)
                local state = getReg(a + 1)
                local v = getReg(a + 2)
                if (type(iter) == "table" or type(iter) == "userdata") and state == nil then
                    local mt = getmetatable(iter)
                    local it = mt and mt.__iter
                    if it then
                        local genIter, genState, genV = it(iter)
                        setReg(a, genIter)
                        setReg(a + 1, genState)
                        setReg(a + 2, genV)
                        iter, state, v = genIter, genState, genV
                    else
                        local genIter, genState, genV = pairs(iter)
                        setReg(a, genIter)
                        setReg(a + 1, genState)
                        setReg(a + 2, genV)
                        iter, state, v = genIter, genState, genV
                    end
                end
                local isIterFn = type(iter) == "function" or (type(iter) == "table" and getmetatable(iter) and getmetatable(iter).__call)
                if isIterFn then
                    local ok, r1, r2, r3, r4, r5, r6 = Pcall(iter, state, v)
                    if ok then
                        local results = { r1, r2, r3, r4, r5, r6 }
                        for i = 1, b do
                            setReg(c + i - 1, results[i])
                        end
                        if getReg(c) ~= nil then
                            setReg(a + 2, getReg(c))
                            _2b7rgh = _2b7rgh + 1
                        end
                    end
                end
            elseif op == 175 then
                local tbl = getReg(a)
                if tbl ~= nil then
                    local startIdx = c > 0 and c or 1
                    local fromReg = b > 0 and b or (a + 1)
                    local count = topReg - fromReg + 1
                    if count > 0 then
                        for i = 0, count - 1 do
                            tbl[startIdx + i] = getReg(fromReg + i)
                        end
                    end
                end
            elseif op == 124 then
                for r in pairs(openUpvalues) do
                    if r >= a then
                        openUpvalues[r] = nil
                    end
                end
            elseif op == 114 then
                local childProto = _f9f2xs[bx + 1]
                local childUpvals = {}
                if childProto.u then
                    for i = 1, #childProto.u do
                        local uDesc = childProto.u[i]
                        local isLocal = (uDesc[1] == 1)
                        local idx = uDesc[2]
                        if isLocal then
                            local uv = openUpvalues[idx]
                            if not uv then
                                uv = { _8huvc6[idx] }
                                openUpvalues[idx] = uv
                            end
                            childUpvals[i] = uv
                        else
                            childUpvals[i] = upvals and upvals[idx + 1]
                        end
                    end
                end
                setReg(a, function(...)
                    local args = { ... }
                    args.n = select('#', ...)
                    return _cqmrqj(childProto, args, env, childUpvals)
                end)
            elseif op == 242 then
                local offset = _cxpt2g.np or 0
                local nArgs = (varargs and (varargs.n or #varargs)) or 0
                if b > 1 then
                    for i = 1, b - 1 do
                        setReg(a + i - 1, varargs and varargs[offset + i])
                    end
                elseif b == 0 then
                    local count = 0
                    for i = offset + 1, nArgs do
                        count = count + 1
                        setReg(a + count - 1, varargs[i])
                    end
                    topReg = a + count - 1
                end
            end

            _2b7rgh = _2b7rgh + 1
        end
    end

    -- Run Root Chunk
    local rootArgs = { ... }
    rootArgs.n = select('#', ...)
    local rootEnv = setmetatable({}, {
        __index = _9fi24g,
        __newindex = function(t, k, v)
            RawSet(t, k, v)
            if _9fi24g then
                _9fi24g[k] = v
            end
        end
    })
    return _cqmrqj(rootChunk, rootArgs, rootEnv, {})
end)(...)
