.pragma library
// omarchy-eliza: share the service trace ceiling when a tracer is requested.
.import "Model.js" as Model

// Charles Hayden's 1998 Java ELIZA, a rework of his 1985 Macintosh program.
// Ported from his Java sources at http://www.chayden.net/eliza/Eliza.html, where he writes:
// "You are welcome to make use of it however you want."

// omarchy-eliza: shared synchronous response budget, inactive during script parsing.
var matchBudget = null;
function matchStep() {
    if (!matchBudget) return true;
    if (matchBudget.remaining <= 0) { matchBudget.exhausted = true; return false; }
    matchBudget.remaining--;
    return true;
}

function amatch(str, pat) {
    let count = 0;
    while (count < str.length && count < pat.length) {
        if (!matchStep()) return -1;
        const p = pat.charAt(count);
        if (p === '*' || p === '#') return count;
        if (str.charAt(count) !== p) return -1;
        count++;
    }
    // hayden: even an exhausted string counts as a partial literal match.
    return count;
}

function findPat(str, pat) {
    for (let i = 0; i < str.length; i++) {
        if (!matchStep()) return -1;
        if (amatch(str.substring(i), pat) >= 0) return i;
    }
    return -1;
}

function match(str, pat, matches) {
    let i = 0, j = 0, pos = 0;
    while (pos < pat.length && j < matches.length) {
        if (!matchStep()) return false;
        const p = pat.charAt(pos);
        if (p === '*' || p === '#') {
            let n = 0;
            if (p === '*') {
                n = pos + 1 === pat.length ? str.length - i :
                    findPat(str.substring(i), pat.substring(pos + 1));
            } else {
                while (i + n < str.length && '0123456789'.indexOf(str.charAt(i + n)) !== -1) { if (!matchStep()) return false; n++; }
            }
            if (n < 0) return false;
            matches[j++] = str.substring(i, i + n);
            i += n;
            pos++;
        } else {
            const n = amatch(str.substring(i), pat.substring(pos));
            if (n <= 0) return false;
            i += n;
            pos += n;
        }
    }
    // hayden: stars take the first literal match, without backtracking.
    return i >= str.length && pos >= pat.length;
}

function translateChars(str, src, dest) {
    for (let i = 0; i < src.length; i++) str = str.split(src.charAt(i)).join(dest.charAt(i));
    return str;
}

function compress(s) {
    if (!s.length) return s;
    let dest = '', c = s.charAt(0);
    for (let i = 1; i < s.length; i++) {
        const next = s.charAt(i);
        if (c === ' ' && (next === ' ' || next === ',' || next === '.')) {
            // Drop this space.
        } else if (c !== ' ' && next === '?') dest += c + ' ';
        else dest += c;
        c = next;
    }
    return dest + c;
}

function trim(s) {
    // hayden: only leading ASCII spaces are trimmed, never trailing spaces.
    for (let i = 0; i < s.length; i++) if (s.charAt(i) !== ' ') return s.substring(i);
    return '';
}

function pad(s) {
    if (!s.length) return ' ';
    return (s.charAt(0) === ' ' ? '' : ' ') + s + (s.charAt(s.length - 1) === ' ' ? '' : ' ');
}

function translate(s, list) {
    const xlate = word => {
        for (let i = 0; i < list.length; i++) if (word === list[i].src) return list[i].dest;
        return word;
    };
    const lines = new Array(2);
    let work = trim(s), result = '';
    while (match(work, '* *', lines)) {
        result += xlate(lines[0]) + ' ';
        work = trim(lines[1]);
    }
    return result + xlate(work);
}

function readScript(text) {
    if (typeof text !== 'string') return { ok: false, error: 'Script must be text.' };
    const script = { keys: [], syns: [], pre: [], post: [], quit: [], initial: 'Hello.', final: 'Goodbye.' };
    let lastDecomp = null, lastReasemb = null;
    const rows = text.split(/\r\n|\n|\r/);
    for (let row = 0; row < rows.length; row++) {
        let s = rows[row];
        const lines = new Array(4);
        if (match(s, '*reasmb: *', lines)) {
            if (!lastReasemb) return { ok: false, error: 'No decomposition for reassembly at line ' + (row + 1) };
            lastReasemb.push(lines[1]);
        } else if (match(s, '*decomp: *', lines)) {
            if (!lastDecomp) return { ok: false, error: 'No key for decomposition at line ' + (row + 1) };
            lastReasemb = [];
            const temp = lines[1];
            const mem = match(temp, '$ *', lines);
            lastDecomp.push({ pattern: mem ? lines[0] : temp, mem: mem, reasemb: lastReasemb });
        } else if (match(s, '*key: * #*', lines)) {
            lastDecomp = [];
            lastReasemb = null;
            // hayden: absent/invalid ranks are zero, despite the format doc saying one.
            const rank = Number(lines[2]);
            script.keys.push({ key: lines[1], rank: rank <= 2147483647 ? rank : 0, decomp: lastDecomp });
        } else if (match(s, '*key: *', lines)) {
            lastDecomp = [];
            lastReasemb = null;
            script.keys.push({ key: lines[1], rank: 0, decomp: lastDecomp });
        } else if (match(s, '*synon: * *', lines)) {
            const words = [lines[1]];
            s = lines[2];
            while (match(s, '* *', lines)) { words.push(lines[0]); s = lines[1]; }
            words.push(s);
            script.syns.push(words);
        } else if (match(s, '*pre: * *', lines)) script.pre.push({ src: lines[1], dest: lines[2] });
        else if (match(s, '*post: * *', lines)) script.post.push({ src: lines[1], dest: lines[2] });
        else if (match(s, '*initial: *', lines)) script.initial = lines[1];
        else if (match(s, '*final: *', lines)) script.final = lines[1];
        else if (match(s, '*quit: *', lines)) script.quit.push(' ' + lines[1] + ' ');
        // hayden: unknown lines, including font and size, are ignored.
    }
    return { ok: true, script: script };
}

class Hayden {
    // tracer is an optional callback receiving each trace line.
    constructor(script, tracer) {
        this.script = script;
        this.tracer = tracer;
        this.trace = '';
        this.finished = false;
        this.memory = [];
        this.rules = new Map();
    }
    initial() { return this.script.initial; }
    // omarchy-eliza: call sites skip trace string construction without a callback.
    log(line) {
        if (!this.tracer) return;
        this.trace = Model.capTrace(this.trace + line + '\n');
        if (typeof this.tracer === 'function') this.tracer(line);
    }
    getKey(word) {
        for (let i = 0; i < this.script.keys.length; i++) {
            if (this.script.keys[i].key === word) return this.script.keys[i];
        }
        return null;
    }
    matchDecomp(str, pat, lines) {
        if (!match(pat, '*@* *', lines)) return match(str, pat, lines);
        const first = lines[0], synWord = lines[1], rest = ' ' + lines[2];
        let syn = null;
        for (let i = 0; i < this.script.syns.length; i++) {
            if (this.script.syns[i].indexOf(synWord) !== -1) { syn = this.script.syns[i]; break; }
        }
        if (!syn) return false;
        // hayden: expands only the first @ class, and any member can name the class.
        for (let i = 0; i < syn.length; i++) {
            if (match(str, first + syn[i] + rest, lines)) {
                const n = first.split('*').length - 1;
                for (let j = lines.length - 2; j >= n; j--) lines[j + 1] = lines[j];
                lines[n] = syn[i];
                return true;
            }
        }
        return false;
    }
    assemble(d, reply, gotoKey) {
        let current = this.rules.has(d) ? this.rules.get(d) : 100;
        // hayden: memory picks randomly, then increments just like ordinary rules.
        if (d.mem) current = Math.floor(Math.random() * d.reasemb.length);
        current++;
        if (current >= d.reasemb.length) current = 0;
        this.rules.set(d, current);
        let rule = d.reasemb[current];
        if (this.tracer) this.log('reasmb: ' + rule);
        const lines = new Array(3);
        if (match(rule, 'goto *', lines)) {
            // hayden: Java would NPE here on the xnone fallback (null holder); we ignore the goto instead.
            if (gotoKey) gotoKey.key = this.getKey(lines[0]);
            return null;
        }
        let work = '';
        while (match(rule, '* (#)*', lines)) {
            rule = lines[2];
            // hayden: a malformed empty number leaves Java's initial index of zero.
            const n = lines[1] === '' ? 0 : Number(lines[1]) - 1;
            if (n < 0 || n >= reply.length) return null;
            // hayden: repeated references translate the captured piece again in place.
            reply[n] = translate(reply[n], this.script.post);
            work += lines[0] + ' ' + reply[n];
        }
        work += rule;
        if (d.mem) {
            // hayden: a full memory silently discards new replies; recall is FIFO.
            if (this.memory.length < 20) this.memory.push(work);
            if (this.tracer) this.log('memory save: ' + work);
            return null;
        }
        return work;
    }
    decompose(key, s, gotoKey) {
        const reply = new Array(10).fill(null);
        if (this.tracer) this.log('key: ' + key.key);
        for (let i = 0; i < key.decomp.length; i++) {
            const d = key.decomp[i];
            if (this.matchDecomp(s, d.pattern, reply)) {
                if (this.tracer) this.log('decomp: ' + d.pattern);
                const rep = this.assemble(d, reply, gotoKey);
                if (rep !== null) return rep;
                if (gotoKey && gotoKey.key !== null) return null;
            }
        }
        return null;
    }
    sentence(s) {
        s = pad(translate(s, this.script.pre));
        if (this.script.quit.indexOf(s) !== -1) {
            this.finished = true;
            return this.script.final;
        }
        const stack = [], lines = new Array(2);
        const push = word => {
            const key = this.getKey(word);
            if (!key) return;
            // hayden: duplicate keywords remain in the stack; equal ranks retain input order.
            // omarchy-eliza: excess keywords are ignored instead of throwing after a user turn.
            if (stack.length >= 20) return;
            let i = stack.length;
            while (i > 0 && key.rank > stack[i - 1].rank) { stack[i] = stack[i - 1]; i--; }
            stack[i] = key;
        };
        let work = trim(s);
        while (match(work, '* *', lines)) { push(lines[0]); work = lines[1]; }
        push(work);
        for (let i = 0; i < stack.length; i++) {
            const gotoKey = { key: null };
            let reply = this.decompose(stack[i], s, gotoKey);
            if (reply !== null) return reply;
            // hayden: the goto holder is reused (not cleared) throughout a chain.
            while (gotoKey.key !== null) {
                // omarchy-eliza: also bound goto cycles that do not consume input.
                if (!matchStep()) return null;
                reply = this.decompose(gotoKey.key, s, gotoKey);
                if (reply !== null) return reply;
            }
        }
        return null;
    }
    processInput(s) {
        // hayden: ASCII case translation, not Unicode lowercasing.
        s = translateChars(s, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz');
        s = translateChars(s, '@#$%^&*()_-+=~`{[}]|:;<>\\"', '                          ');
        s = compress(translateChars(s, ',?!', '...'));
        const lines = new Array(2);
        while (match(s, '*.*', lines)) {
            const reply = this.sentence(lines[0]);
            if (reply !== null) return reply;
            s = trim(lines[1]);
        }
        if (s.length) {
            const reply = this.sentence(s);
            if (reply !== null) return reply;
        }
        if (this.memory.length && (!matchBudget || !matchBudget.exhausted)) {
            const memory = this.memory.shift();
            if (this.tracer) this.log('memory recall: ' + memory);
            return memory;
        }
        // omarchy-eliza: reserve a separate bounded attempt for the script fallback.
        if (matchBudget) matchBudget = {remaining: 1000, exhausted: false};
        const key = this.getKey('xnone');
        if (key !== null) {
            const reply = this.decompose(key, s, null);
            if (reply !== null) return reply;
        }
        return 'I am at a loss for words.';
    }
    response(input) {
        this.trace = '';
        // omarchy-eliza: no budget state leaks into another response or script load.
        matchBudget = {remaining: 100000, exhausted: false};
        try { return { text: this.processInput(input), finished: this.finished }; }
        finally { matchBudget = null; }
    }
}

var api = { readScript: readScript, Hayden: Hayden };
