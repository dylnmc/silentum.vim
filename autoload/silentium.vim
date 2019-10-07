
function! s:print(group) " (:
	let l:color = g:silentium#colors[a:group]
	exec printf('hi silentium_%s_hi guifg=%s ctermfg=%d', a:group, g:silentium#xterm_colors[l:color], l:color)
	if a:group ==# 'bg'
		exec printf('hi silentium_%s_hi guibg=white ctermbg=255', a:group)
	endif
	exec printf('echohl silentium_%s_hi', a:group)
	let l:def = g:silentium#defaults[a:group]
	let l:i = get(g:, 'silentium_'.a:group, l:def)
	echom printf('%s[%d] -> %s %s -> default%s', a:group, l:i, l:color, g:silentium#xterm_colors[l:color], l:i ==# l:def ? '' : printf(': %s[%d]', a:group, l:def))
	exec printf('hi clear silentium_%s_hi', a:group)
	echohl NONE
endfunction " :)

function! silentium#color_set(bang, ...) " (:
	if !a:0
		let l:group = ''
		if a:bang
			for l:key in keys(g:silentium#colors)
				if exists('g:silentium_'.l:key)
					unlet g:['silentium_'.l:key]
				endif
			endfor
		else
			echohl ErrorMsg
			echom 'USAGE: :Silentium[!] [group [[+-]num]]'
			echohl NONE
			return
		endif
	else
		let l:bang = a:bang
		let l:args = split(a:1)
		let l:group = l:args[0]
		if l:group[-1:] ==# '!'
			let l:bang = 1
			let l:group = l:group[:-2]
		endif
		if len(l:args) > 1
			let l:val = l:args[1]
			if l:val[0] =~# '[+-]'
				let l:num = get(g:, 'silentium_'.l:group, g:silentium#defaults[l:group]) + eval(l:val[0] . str2nr(l:val[1:]))
			else
				let l:num = str2nr(l:val)
			endif
			let g:['silentium_'.l:group] = min([g:silentium#maxes[l:group] - 1, max([0, l:num])])
		else
			if l:bang
				if exists('g:silentium_'.l:group)
					unlet g:['silentium_'.l:group]
				endif
			else
				call s:print(l:group)
				return
			endif
		endif
	endif
	let l:top = line('w0')
	redraw!
	mkview
	colorscheme silentium
	if expand('%:p:t') ==# 'silentium.vim'
		silent edit
		normal! zv
	endif
	loadview
	let l:newtop = line('w0')
	if l:top !=# l:newtop
		execute 'normal! '.repeat("\<c-y>", l:newtop - l:top)
	endif
	redraw!
	if empty(l:group)
		echom 'Silentium defaults reset'
	else
		call s:print(l:group)
	endif
endfunction " :)

function! silentium#color_set_compl(arglead, cmdline, curpos) abort " (:
	let l:args = split(a:cmdline, '\s\+')
	let l:argn = len(l:args)
	if l:argn ==# 1
		return keys(g:silentium#maxes)
	elseif l:argn ==# 2
		if a:cmdline =~# '\s\+$'
			return map(range(0, g:silentium#maxes[l:args[1]]), { _,v -> string(v) })
		endif
		return filter(keys(g:silentium#maxes), { _,v -> stridx(v, a:arglead) ==# 0 })
	elseif l:argn ==# 3
		if a:cmdline !~# '\s\+$'
			return map(range(0, g:silentium#maxes[l:args[1]]), { _,v -> string(v) })
		endif
	endif
	return []
endfunction " :)

function! silentium#setup_colors(init) " (:
	if expand('%:p') !~# '\/colors\/silentium\.vim$' || get(b:, 'silentium_no_setup')
		return
	endif
	nnoremap <buffer> <silent> ) <c-a>:update<cr>
	nnoremap <buffer> <silent> ( <c-x>:update<cr>
	if !get(b:, 'silentium_colors_setup')
		autocmd BufWinEnter <buffer> call silentium#setup_colors(0)
		autocmd BufWinLeave <buffer> call clearmatches()
		autocmd BufWritePost <buffer> if !get(b:, 'silentium_no_setup')|try|colo silentium|call silentium#setup_colors(0)|catch|redraw!|echoerr 'Error loading silentium.vim'|endtry|endif
		let b:silentium_colors_setup = 1
	endif
	call clearmatches()
	let l:linenr = 0
	for l:line in getline(1, '$')
		let l:linenr += 1
		if l:line =~# '^H\s\+\w'
			call matchaddpos(split(l:line, '\s\+')[1], [[l:linenr]])
		elseif l:line =~# '^\s*call\s\+s:\%(set\|link\)Color\s*('
			let l:name = substitute(l:line, '^\s*call\s\+s:\%(set\|link\)Color(\(["'']\)\(.\{-}\)\1.*', '\2', '')
			let l:group = 'silentium_'.l:name
			let l:col = get(g:silentium#colors, l:name, -1)
			if l:col ==# -1
				continue
			endif
			exec printf('hi %s guifg=%s ctermfg=%d', l:group, g:silentium#xterm_colors[l:col], l:col)
			if l:name ==# 'bg'
				exec printf('hi %s guibg=%s ctermbg=%d', l:group, g:silentium#xterm_colors[g:silentium#colors.fg], g:silentium#colors.fg)
			endif
			call matchaddpos(l:group, [[l:linenr - 1, 3, strlen(getline(l:linenr - 1)) - 2]])
		endif
	endfor
	" if 
	if &termguicolors
		let [l:linenr,l:colnr] = searchpos('let\s\+g:silentium#xterm_colors\s*=\s*\[\s*\zs\S', 'n')
		let l:colnr += 1
		let l:line = split(getline(l:linenr)[l:colnr-1 : -4], "', '")
		for l:i in range(256)
			let l:col = 'xterm_col_'.l:i
			execute printf('hi %s guifg=%s', l:col, l:line[l:i])
			call matchaddpos(l:col, [[l:linenr, l:colnr + 11 * l:i, 7]])
			let l:nums = printf('%3d', l:i)
			call matchaddpos('Conceal', [[l:linenr, l:colnr + 11 * l:i - 4, 1]], 11, -1, { 'conceal': l:nums[0] })
			call matchaddpos('Conceal', [[l:linenr, l:colnr + 11 * l:i - 3, 1]], 11, -1, { 'conceal': l:nums[1] })
			call matchaddpos('Conceal', [[l:linenr, l:colnr + 11 * l:i - 2, 1]], 11, -1, { 'conceal': l:nums[2] })
			call matchaddpos('Conceal', [[l:linenr, l:colnr + 11 * l:i - 1, 1]], 11, -1, { 'conceal': ':' })
		endfor
	endif
	if !a:init
		if exists('#User#SilentiumColorUpdate')
			doautocmd User SilentiumColorUpdate
		endif
	endif
endfunction " :)

" vim: fdm=marker fmr=\(\:,\:\) fdl=0:
