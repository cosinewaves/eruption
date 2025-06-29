--!strict

-- Types
export type log = {
	print: (outer: string, inner: string, content: string) -> (),
	warn: (outer: string, inner: string, content: string) -> (),
	error: (outer: string, inner: string, content: string, level: number?) -> ()
}

local log = {} :: log

local function format(outer: string, inner: string, content: string): string
	return `[eruption.{outer}.{inner}]: {content}`
end

function log.print(outer: string, inner: string, content: string): ()
	print(format(outer, inner, content))
end

function log.warn(outer: string, inner: string, content: string): ()
	warn(format(outer, inner, content))
end

function log.error(outer: string, inner: string, content: string, level: number?): ()
	error(format(outer, inner, content), level or 1)
end

return log
