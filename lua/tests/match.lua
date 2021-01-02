local eq = function(a, b)
  assert.are.same(a, b)
end

describe('link match', function()
  it('should match correctly', function()
    local word = '[[[adfasdaad]]]'

    local left_id = string.match(word, '%[%[(.*)%]%]') -- if it is [[id]]
    local right_id = string.match(left_id or '', '%[(.*)%]') -- check if there is one more layer of [], if it is [[[id]]]
    local id = right_id or left_id

    if id == nil then
      error("There is no link under the cursor")
    end

    eq('adfasdaad', 5)
  end)
end)
