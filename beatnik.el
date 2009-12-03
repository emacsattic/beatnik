;; beatnik.el -- Tries to implement a beatnik interpreter
;;

;; Author Arjan Bos <Arjan.Bos@hetnet.Netherlands>
;; Keywords: esoterica beatnik
;; Version
(defconst beatnik-version "1.0")
;; 
;;
;;	Copyright (C) 2004 Arjan Bos.
;;
;;	This file is NOT part of GNU Emacs (yet).
;;
;;
;; DISTRIBUTION
;; Copyright (C) 2004 Arjan Bos

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; It is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;
;;
;; Commentary:
;; This mode contains a font-locking mechanism that uses functions as
;; matchers, instead of regexps. Many thanks to Stefan Monnier who
;; took the time to explain it to me!

;; The complete beatnik definition is written by Cliff L. Biffle.
;; It can be found at:
;; http://www.cliff.biffle.org/esoterica/beatnik.html
;;
;; The following text is taken directly from that site:
;; Beatnik is a very simple language to learn: it has a small set of
;; commands, a very relaxed syntax, and you can find a reference to
;; its vocabulary at any toy store.
;;
;; A Beatnik program consists of any sequence of English words,
;; separated by any sort of punctuation from spaces to hyphens to
;; blank pages. Thus, "Hello, aunts! Swim around brains!" is a valid
;; Beatnik program, despite not making much sense.  (If you're
;; wondering, that reads a character from the user, adds seven to it
;; [i.e. A -> H], and prints it out.)
;;
;; The function of a particular word--say, brains, or aunts--is
;; determined by the score one would receive for playing that word in
;; Scrabble. Thus, "hello" gets us 8 points, and so on.
;;
;; Before we explain how the scores are matched up to the functions,
;; there are a couple things you must know.  When Beatnik does
;; arithmetic, it does it on a stack. For those of you who don't spend
;; as much time doing this stuff as I do, a stack is very simple: you
;; can push things onto the top of it, or take things off the top of
;; it (in order, from top to bottom), and that's it. So, if you push 2
;; and 3, and then do an "add", 2 and 3 are "popped", added into 5,
;; and then 5 is "pushed".

;; The numbers Beatnik deals with can range from 0 to 255.
;; 
;;  Score
;; Function
;; 
;; <5 
;; Does nothing. The Beatnik Interpreter may mock you for your poor
;; scoring, at its discretion. Low scoring words such as "I" or "of"
;; are probably not good words to program with immediately after
;; stealing all of the interpreter's cigarettes and stomping on its
;; beret.
;; 
;; 5 
;; Finds the score of the next word and pushes it onto the
;; stack. Skips the aforementioned next word.
;; 
;; 6
;; Pops the top number off the stack and discards it.
;; 
;; 7
;; Adds the top two values on the stack together (as described above)
;; 
;; 8
;; Input a character from the user and push its value on the
;; stack. Waits for a keypress.
;; 
;; 9
;; Pop a number off the stack and output the corresponding ASCII
;; character to the screen.
;; 
;; 10
;; Subtract the top value on the stack from the next value on the
;; stack, pushing the result.
;; 
;; 11
;; Swap the top two values on the stack.
;; 
;; 12
;; Duplicate the top value.
;; 
;; 13
;; Pop a number from the stack, and figure out the score of the next
;; word. If the number from the stack is zero, skip ahead by n words,
;; where n is the score of the next word. (The skipping is actually
;; n+1 words, because the word scored to give us n is also skipped.)
;; 
;; 14
;; Same as above, except skip if the value on the stack isn't zero.
;; 
;; 15
;; Skip back n words, if the value on the stack is zero.
;; 
;; 16
;; Skip back if it's not zero.
;; 
;; 17
;; Stop the program.
;; 
;; 18-23
;; Does nothing. However, the score is high enough that the Beatnik
;; Interpreter will not mock you, unless it's had a really bad day.
;; 
;; >23
;; Garners "Beatnik applause" for the programmer. This generally
;; consists of reserved finger-snapping.
;; 
;; By this point, you're probably wondering why it's called
;; Beatnik. Well, you're about to find out. Here is the source for a
;; program that simply prints "Hi" to the screen.
;; 
;; Baa, badassed areas!
;; Jarheads' arses
;;       queasy nude adverbs!
;;     Dare address abase adder? *bares baser dadas* HA!
;; Equalize, add bezique, bra emblaze.
;;   He (quezal), aeons liable.  Label lilac "bulla," ocean sauce!
;; Ends, addends,
;;    duodena sounded amends.
;; 
;;  See?
;; 
;; The scrabble score is taken from
;; http://encyclopedia.thefreedictionary.com/Scrabble
;; 
;; English language editions of the game contain 100 letter tiles, in
;; the following distribution:
;; blank -  0
;; A     -  1
;; B     -  3
;; C     -  3
;; D     -  2
;; E     -  1
;; F     -  4
;; G     -  2
;; H     -  4
;; I     -  1
;; J     -  8
;; K     -  5
;; L     -  1
;; M     -  3
;; N     -  1
;; O     -  1
;; P     -  3
;; Q     - 10
;; R     -  1
;; S     -  1
;; T     -  1
;; U     -  1
;; V     -  4
;; W     -  4
;; X     -  8
;; Y     -  4
;; Z     - 10
;; Editions in other languages vary greatly because the letter
;; distribution and values are adapted to the frequency of letters in
;; the language.

(defgroup beatnik nil
  "Groups together all customization possibilities for Beatnik."
  :group 'languages)

(defcustom scrabble-list '(("a"  1)
			   ("b"  3)
			   ("c"  3)
			   ("d"  2)
			   ("e"  1)
			   ("f"  4)
			   ("g"  2)
			   ("h"  4)
			   ("i"  1)
			   ("j"  8)
			   ("k"  5)
			   ("l"  1)
			   ("m"  3)
			   ("n"  1)
			   ("o"  1)
			   ("p"  3)
			   ("q" 10)
			   ("r"  1)
			   ("s"  1)
			   ("t"  1)
			   ("u"  1)
			   ("v"  4)
			   ("w"  4)
			   ("x"  8)
			   ("y"  4)
			   ("z" 10))
  "*This variable holds the scrabble scoring that drives beatnik."
  :group 'beatnik
  :type 'list)

(defvar beatnik-mode-hook nil)

(defvar beatnik-stack ()
  "The working stack of Beatnik. All word scores are pushed and
  popped from this stack.")

(defvar beatnik-mode-map nil
  "Keymap for Beatnik")

(if beatnik-mode-map
    nil
  ;; else
  (progn
    (setq beatnik-mode-map (make-keymap))
    (define-key beatnik-mode-map "\C-c\C-e" 'beatnik-eval)))

(defcustom beatnik-font-lock-<5-face 'beatnik-font-lock-<5-face
  "Specify Face used to color words which score less than 5."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-<5-face
  '((((class color)
      (background light))
     (:weight normal :foreground "lightcyan4" :strike-through "red")))
  "Face used to color words which score less than 5.")

(defcustom beatnik-font-lock-=5-face 'beatnik-font-lock-=5-face
  "Specify Face used to color words which score 5."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=5-face
  '((((class color)
      (background light))
     (:weight normal :foreground "blue" )))
  "Face used to color words which score 5.")

(defcustom beatnik-font-lock-=6-face 'beatnik-font-lock-=6-face
  "Specify Face used to color words which score 6."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=6-face
  '((((class color)
      (background light))
     (:weight normal :slant italic :foreground "blue" )))
  "Face used to color words which score 6.")

(defcustom beatnik-font-lock-=7-face 'beatnik-font-lock-=7-face
  "Specify Face used to color words which score 7."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=7-face
  '((((class color)
      (background light))
     (:weight bold :foreground "blue")))
  "Face used to color words which score 7.")

(defcustom beatnik-font-lock-=8-face 'beatnik-font-lock-=8-face
  "Specify Face used to color words which score 8."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=8-face
  '((((class color)
      (background light))
     (:weight bold :slant italic :foreground "blue")))
  "Face used to color words which score less than 5.")

(defcustom beatnik-font-lock-=9-face 'beatnik-font-lock-=9-face
  "Specify Face used to color words which score 9."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=9-face
  '((((class color)
      (background light))
     (:weight normal :foreground "darkgreen")))
  "Face used to color words which score 9.")

(defcustom beatnik-font-lock-=10-face 'beatnik-font-lock-=10-face
  "Specify Face used to color words which score 10."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=10-face
  '((((class color)
      (background light))
     (:weight normal :slant italic :foreground "darkgreen")))
  "Face used to color words which score 10.")

(defcustom beatnik-font-lock-=11-face 'beatnik-font-lock-=11-face
  "Specify Face used to color words which score 11."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=11-face
  '((((class color)
      (background light))
     (:weight bold :foreground "darkgreen")))
  "Face used to color words which score 11.")

(defcustom beatnik-font-lock-=12-face 'beatnik-font-lock-=12-face
  "Specify Face used to color words which score 12."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=12-face
  '((((class color)
      (background light))
     (:weight bold :slant italic :foreground "darkgreen")))
  "Face used to color words which score 12 .")

(defcustom beatnik-font-lock-=13-face 'beatnik-font-lock-=13-face
  "Specify Face used to color words which score 13."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=13-face
  '((((class color)
      (background light))
     (:weight normal :foreground "steelblue")))
  "Face used to color words which score 13.")

(defcustom beatnik-font-lock-=14-face 'beatnik-font-lock-=14-face
  "Specify Face used to color words which score 14."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=14-face
  '((((class color)
      (background light))
     (:weight normal :slant italic :foreground "steelblue")))
  "Face used to color words which score 14.")

(defcustom beatnik-font-lock-=15-face 'beatnik-font-lock-=15-face
  "Specify Face used to color words which score 15."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=15-face
  '((((class color)
      (background light))
     (:weight bold :foreground "steelblue")))
  "Face used to color words which score 15.")

(defcustom beatnik-font-lock-=16-face 'beatnik-font-lock-=16-face
  "Specify Face used to color words which score 16."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=16-face
  '((((class color)
      (background light))
     (:weight bold :slant italic :foreground "steelblue")))
  "Face used to color words which score 16.")

(defcustom beatnik-font-lock-=17-face 'beatnik-font-lock-=17-face
  "Specify Face used to color words which score 17."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock-=17-face
  '((((class color)
      (background light))
     (:weight bold :foreground "red")))
  "Face used to color words which score 17.")

(defcustom beatnik-font-lock->=18-<=23-face 'beatnik-font-lock->=18-<=23-face
  "Specify Face used to color words which score 18 or more, or 23 or less."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock->=18-<=23-face
  '((((class color)
      (background light))
     (:weight normal :foreground "purple" :underline t)))
  "Face used to color words which score 18 or more, or 23 or less.")

(defcustom beatnik-font-lock->23-face 'beatnik-font-lock->23-face
  "Specify Face used to color words which score more than 23."
  :type 'face
  :group 'faces
  :group 'beatnik)

(defface beatnik-font-lock->23-face
  '((((class color)
      (background light))
     (:weight normal :foreground "red" :underline "blue" :overline "blue")))
  "Face used to color words which score more than 23.")

(defconst beatnik-font-lock-keywords 
  '((beatnik-<5-p-matcher  (1 beatnik-font-lock-<5-face ))
    (beatnik-=5-p-matcher  (1 beatnik-font-lock-=5-face ))
    (beatnik-=6-p-matcher  (1 beatnik-font-lock-=6-face ))
    (beatnik-=7-p-matcher  (1 beatnik-font-lock-=7-face ))
    (beatnik-=8-p-matcher  (1 beatnik-font-lock-=8-face ))
    (beatnik-=9-p-matcher  (1 beatnik-font-lock-=9-face ))
    (beatnik-=10-p-matcher (1 beatnik-font-lock-=10-face))
    (beatnik-=11-p-matcher (1 beatnik-font-lock-=11-face))
    (beatnik-=12-p-matcher (1 beatnik-font-lock-=12-face))
    (beatnik-=13-p-matcher (1 beatnik-font-lock-=13-face))
    (beatnik-=14-p-matcher (1 beatnik-font-lock-=14-face))
    (beatnik-=15-p-matcher (1 beatnik-font-lock-=15-face))
    (beatnik-=16-p-matcher (1 beatnik-font-lock-=16-face))
    (beatnik-=17-p-matcher (1 beatnik-font-lock-=17-face))
    (beatnik-=>18-<=23-p-matcher (1 beatnik-font-lock->=18-<=23-face))
    (beatnik->23-p-matcher (1 beatnik-font-lock->23-face))
    )
  "font locking for beatnik-mode. Done with functions")

(defconst beatnik-font-matcher-regexp
  "\\<\\(.+?\\)\\>"
  "Regular expression used to match words in beatnik") 

(defun beatnik-<5-p-matcher (limit)
  "returns t when the scrabble score of a word is less than 5."
  (let (found)
    (while (and (setq found (re-search-forward 
			     beatnik-font-matcher-regexp limit t))
		(> (beatnik-last-word-score) 4)))
    found))
;;   ;; no point in searching past limit
;;   (if (and (re-search-forward beatnik-font-matcher-regexp limit t)
;; 	   (< (beatnik-last-word-score) 5))
;;       (progn
;; 	(setq beatnik-last-match (list (match-string-no-properties 1)
;; 				       limit
;; 				       "<5"
;; 				       (point)))
;; 	t)
;;     ;; else
;;     (if (equal (list (match-string-no-properties 1) 
;; 		     limit
;; 		     "<5"
;; 		     (point))
;; 	       beatnik-last-match)
;; 	;; we already found it, return nil
;; 	(progn
;; 	  nil)
;;       ;; else
;;       (while (and (re-search-forward beatnik-font-matcher-regexp limit t)
;; 		  (not (< (beatnik-last-word-score) 5))))
;;       (if (< (beatnik-last-word-score) 5)
;; 	  (progn
;; 	    (setq beatnik-last-match (list (match-string-no-properties 1)
;; 					   limit
;; 					   "<5"
;; 					   (point)))
;; 	    t)
;; 	;; else
;; 	nil))))

(defun beatnik-tester ()
  "tests a font-locking matcter function"
  (interactive)
  (beatnik-=>18-<=23-p-matcher (point-max)))

(defvar beatnik-last-match ()
  "Contains list of last match, limit, score-match and `point' used.")

(defun beatnik-=-matcher-p (limit score-match)
  "Tries to find a word whose scrable score matches score-match. 
If such a word was found, t is returned."
  (let (found)      
     (while (and (setq found (re-search-forward
			      beatnik-font-matcher-regexp limit t))
		 (/= (beatnik-last-word-score) score-match)))
     found))

(defun beatnik-=5-p-matcher (limit)
  "returns t when the scrabble score of a word equals 5."
  (beatnik-=-matcher-p limit 5))

(defun beatnik-=6-p-matcher (limit)
  "returns t when the scrabble score of a word equals 6."
  (beatnik-=-matcher-p limit 6))

(defun beatnik-=7-p-matcher (limit)
  "returns t when the scrabble score of a word equals 7."
  (beatnik-=-matcher-p limit 7))

(defun beatnik-=8-p-matcher (limit)
  "returns t when the scrabble score of a word equals 8."
  (beatnik-=-matcher-p limit 8))

(defun beatnik-=9-p-matcher (limit)
  "returns t when the scrabble score of a word equals 9."
  (beatnik-=-matcher-p limit 9))

(defun beatnik-=10-p-matcher (limit)
  "returns t when the scrabble score of a word equals 10."
  (beatnik-=-matcher-p limit 10))

(defun beatnik-=11-p-matcher (limit)
  "returns t when the scrabble score of a word equals 11."
  (beatnik-=-matcher-p limit 11))

(defun beatnik-=12-p-matcher (limit)
  "returns t when the scrabble score of a word equals 12."
  (beatnik-=-matcher-p limit 12))

(defun beatnik-=13-p-matcher (limit)
  "returns t when the scrabble score of a word equals 13."
  (beatnik-=-matcher-p limit 13))

(defun beatnik-=14-p-matcher (limit)
  "returns t when the scrabble score of a word equals 14."
  (beatnik-=-matcher-p limit 14))

(defun beatnik-=15-p-matcher (limit)
  "returns t when the scrabble score of a word equals 15."
  (beatnik-=-matcher-p limit 15))

(defun beatnik-=16-p-matcher (limit)
  "returns t when the scrabble score of a word equals 16."
  (beatnik-=-matcher-p limit 16))

(defun beatnik-=17-p-matcher (limit)
  "returns t when the scrabble score of a word equals 17."
  (beatnik-=-matcher-p limit 17))

(defun beatnik-=>18-<=23-p-matcher (limit)
  "returns t when the scrabble score of a word is between 18 and 23 (inclusive)."
;;   (message "beatnik-=>18-<=23-p-matcher (%d) (%d)" limit (point))
  (let (found)
    (while (setq found (and (re-search-forward
			     beatnik-font-matcher-regexp limit t)
			    (< (beatnik-last-word-score) 18)
			    (> (beatnik-last-word-score) 23))))
    found))
		
(defun beatnik->23-p-matcher (limit)
  "returns t when the scrabble score of a word is greater than 23."
  (let (found)
    (while (and (setq found (re-search-forward
			     beatnik-font-matcher-regexp limit t))
		(< (beatnik-last-word-score) 24)))
    found))

(defun beatnik-find-word-for-score (score)
  "Moves point forward to the first word that has a scrabble value of SCORE."
  (interactive "Nscore: ")
  (let ((beg (point)))
    ;;(goto-char (point-min))
    (while (not (or (= (beatnik-word-score (beatnik-next-word)) score)
		    (eobp))))
    (if (not (eobp))
      (setq beg (point))
      ;; else
      (message "No match found for %d" score))
    (goto-char beg)))

(defun beatnik-find-all-words-for-score (score)
  "Takes all words from the current buffer that match SCORE and puts them in a separate buffer."
  (interactive "Nscore: ")
  (goto-char (point-min))
  (let ((old-buffer (current-buffer))
	(buffer (get-buffer-create "*beatnik-help*"))
	word)
    (set-buffer buffer)
    (kill-region (point-min) (point-max))
    (beatnik-mode)
    (set-buffer old-buffer)
    (while (not (or (eobp)
		    (save-excursion (forward-word 1) (eobp))))
      (setq word (beatnik-next-word))
      (when (= (beatnik-word-score word) score)
	(set-buffer buffer)
	(insert (downcase word) " ")
	(set-buffer old-buffer)))
    (set-buffer buffer)
    (display-buffer buffer)
    (when (< (point-min) (point-max))
      (message "formatting buffer")
      (delete-trailing-whitespace)
      (replace-string " " "\n" nil (point-min) (point-max))
      (sort-lines nil (point-min) (point-max))
      (flush-lines "^$" (point-min) (point-max))
      ;; remove double entries
      (goto-char (point-min))
      (setq word (beatnik-next-word))
      (message "removing double entries")
      (while (not (eobp))
	(if (equal (beatnik-return-word) word)
	    (kill-word 1)
	  ;; else
	  (setq word (beatnik-next-word))))
      (message "filling paragraph")
      (fill-paragraph nil)
      (message "done"))))

(defun beatnik-last-word-score ()
  "Returns the scrabble score of the string contained in `match-string'."
  (beatnik-word-score (match-string-no-properties 1)))

(defun beatnik-current-word-score ()
  "returns the scrabble score of the word at point."
  (interactive)
  (beatnik-give-word-score))

(defun beatnik-give-word-score (&optional str)
  "Returns the scrabble score of a word."
  (interactive "sWord: ")
  (if str
      (message "%s scores %d." str (beatnik-word-score str))
    ;; else
    (message "%s scores %d" (beatnik-return-word) (beatnik-word-score (beatnik-return-word)))))
	
(defun beatnik-word-score (str)
  "Returns the scrabble word score for str"
  (let ((n 0)
	(score 0))
    (setq str (downcase str))
    (while (< n (length str))
      (setq score (+ score (beatnik-letter-score (substring str n (+ n 1))))
	    n (+ n 1)))
    score))

(defun beatnik-letter-score (letter)
  "Returns the scrabble value of letter."
  (let ((tmpList scrabble-list)
	(score 0))
  (setq tmpList scrabble-list)
  (while tmpList
    (if (string= (car (car tmpList)) letter)
	(setq score (car (cdr (car tmpList)))
	      tmpList ())
      ;; else
      (setq tmpList (cdr tmpList))))
  score))

(defun beatnik-return-word ()
  "returns word at or under point."
  (save-excursion
    (beatnik-next-word)))

(defconst beatnik-word-finder
"\t\\|$\\|-\\|;\\|:\\|/\\|>\\|<\\|]\\|\\\\\\|~\\|#\\|\"\\|,\\|."
"")

(defun beatnik-next-word ()
  "returns word at or under point and moves point to the next word."
  (interactive)
  (let (beg end)
;;     (when (not (looking-at (concat "\\<\\ " beatnik-word-finder )))
;;       (forward-word -1))
    (forward-word 1)
    (forward-word -1)
    (setq beg (point))
    (forward-word 1)
    (setq end (point))
    (buffer-substring-no-properties beg end)))

(defun beatnik-eval ()
  "Evaluates everything in buffer before point."
  (interactive)
  (let ((old-buffer (current-buffer))
	(buffer (get-buffer-create "*beatnik*")))
    (display-buffer buffer)
    (set-buffer buffer)
    (kill-region (point-min) (point-max))
    (set-buffer old-buffer)
    (setq beatnik-stack ())
    (let ((beg (point-min))
	  (end (point))
	  word
	  score)
      (save-excursion
	(goto-char beg)
	(while (< (point) end)
	  (setq word (beatnik-next-word)
		score (beatnik-word-score word))
;;	  (set-buffer buffer)
	  (cond ((< score 5)
		 (beatnik-<5))
		((= score 5)
		 (beatnik-=5))
		((= score 6)
		 (beatnik-=6))
		((= score 7)
		 (beatnik-=7))
		((= score 8)
		 (beatnik-=8))
		((= score 9)
		 (beatnik-=9))
		((= score 10)
		 (beatnik-=10))
		((= score 11)
		 (beatnik-=11))
		((= score 12)
		 (beatnik-=12))
		((= score 13)
		 (beatnik-=13))
		((= score 14)
		 (beatnik-=14))
		((= score 15)
		 (beatnik-=15))
		((= score 16)
		 (beatnik-=16))
		((= score 17)
		 ;; stops the interpreter
		 (setq end (point)))
		((and (< score 24)
		      (> score 17))
		 (beatnik-=>18-<=23))
		((> score 23)
		 (beatnik->23)))
	  (message "%s (%d) stack: %s" word score beatnik-stack)
;;	  (message "%s" beatnik-stack)
)))))

(defun beatnik-<5 ()
  "Does nothing. 

The Beatnik Interpreter may mock you for your poor scoring, at
its discretion. Low scoring words such as \"I\" or \"of\" are
probably not good words to program with immediately after
stailing all of the interpreter's cigarettes and stomping on its
beret"
  (when (< (random 10) 2)
    (message "mock mock mock")))

(defun beatnik-=5 ()
  "Finds the score of the next word and pushes it onto the `beatnik-stack'. 
Skips the aforementioned next word."
  (let (score)
    (setq score (beatnik-word-score (beatnik-next-word))
	  score (beatnik-put-score-in-range score)
	  beatnik-stack (cons score beatnik-stack))))

(defun beatnik-=6 ()
  "Pops the top number of the `beatnik-stack' and discards it."
  (setq beatnik-stack (cdr beatnik-stack)))

(defun beatnik-=7 ()
  "Adds the top two values of the `beatnik-stack' together. 

if you push 2 and 3, and then do an \"add\", 2 and 3 are
 \"popped\", added into 5, and then 5 is \"pushed\"."
  (if (> (length beatnik-stack) 1)
      (let (a b sum)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      b (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      sum (beatnik-put-score-in-range (+ a b))
	      beatnik-stack (cons sum beatnik-stack)))
    ;; else
    (message "There is only one item on the stack. No addition done.")))

(defun beatnik-=8 ()
  "Input a character from the user and push its (scrabble) value
on the `beatnik-stack'. Waits for a keypress."
  (interactive "sPress Key: ")
  (setq beatnik-stack (cons (car (string-to-list 
				  (read-string "Press Character: ")))
			    beatnik-stack)))

(defun beatnik-=9 ()
  "Pop a number of the `beatnik-stack' and output the corresponding ASCII
character to the screen."
  (if (> (length beatnik-stack) 0)
      (let ((old-buffer (current-buffer))
	    (buffer (get-buffer-create "*beatnik*")))
	(display-buffer buffer)
	(set-buffer buffer)
	(goto-char (point-max)) ;; why is this needed?
	(insert (car beatnik-stack))
	(set-buffer old-buffer)
	(setq beatnik-stack (cdr beatnik-stack)))
    ;; else
    (message "Stack is empty. No output written.")))

(defun beatnik-=10 ()
  "Subtract the top value on the `beatnik-stack' from the next value on the
`beatnik-stack', pushing the result."
  (if (> (length beatnik-stack) 1)
      (let (a b dif)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      b (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      dif (beatnik-put-score-in-range (- b a))
	      beatnik-stack (cons dif beatnik-stack)))
    ;; else
    (message "There is only one or zero item on the stack. No subtraction done.")))

(defun beatnik-=11 ()
  "Swap the top two values on the `beatnik-stack'."
  (if (> (length beatnik-stack) 1)
      (let (a b)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      b (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack)
	      beatnik-stack (cons a beatnik-stack)
	      beatnik-stack (cons b beatnik-stack)))
    ;; else
    (message "No two values available on stack. Nothing swapped.")))

(defun beatnik-=12 ()
  "Duplicate the top value. Presumably this means that a value is
popped and then pushed back twice."
  (if (> (length beatnik-stack) 0)
      (setq beatnik-stack (cons (car beatnik-stack) beatnik-stack))
    ;; else
    (message "empty stack, nothing to duplicate.")))

(defun beatnik-=13 ()
  "Pop a number from the stack, and figure out the score of the next word.  

If the number from the `beatnik-stack' is zero, skip ahead by n
words, where n is the (scrabble) score of the next word. (The
skipping is actually (+ n 1) words, because the word scored to
give us n is also skipped.)"
  (let (a)
    (setq a (car beatnik-stack)
	  beatnik-stack (cdr beatnik-stack))
    (when (or (null a)
	      (= a 0))
      (if (forward-word 1)
	  (let (n)
	    (forward-word -1)
	    (setq n (beatnik-word-score (beatnik-next-word)))
	    (setq n (beatnik-put-score-in-range n))
	    (when (not (forward-word n))
	      (message "not enough words to skip (needed %d)" n)))
	;; else
	(message "no word to skip to. Missing arg for skip function")))))

(defun beatnik-=14 ()
  "Same as `beatnik-=13', except skip if the value on the stack isn't zero."
  (if (> (length beatnik-stack) 0)
      (let (a)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack))
	(when (not (= a 0))
	  (if (forward-word 1)
	      (let (n)
		(forward-word -1)
		(setq n (beatnik-word-score (beatnik-next-word)))
		(setq n (beatnik-put-score-in-range n))
		(when (not (forward-word n))
		  (message "not enough words to skip (needed %d)" n)))
	    ;; else
	    (message "no word to skip to. Missing arg for skip function"))))
    ;; else
    (message "Empty stack, so don't know wheter or not to skip the following words.")))

(defun beatnik-=15 ()
  "Skip back n words, if the value on the stack is zero. 

Reads the next word, calulates its scrabble score and sets n to
that score. Then it skips back n words. (Actually, (- n 1) words
are skipped back, since the word just read needs to be skipped
back too."
  (if (> (length beatnik-stack) 0)
      (let (a)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack))
	(when (= a 0)
	  (if (forward-word 1)
	      (let (n)
		(setq n (beatnik-word-score (beatnik-next-word)))
		(setq n (beatnik-put-score-in-range n))
		(when (not (backward-word n))
		  (message "not enough words to skip back to (needed %d)." n)))
	    ;; else
	    (message "No argument for skip-back function"))))
    ;; else
    (message "Empty stack. Don't know whether or not to skip words.")))

(defun beatnik-=16 ()
  "Skip back n words, if the value on the stack isn't zero.

See also `beatnik-=15' and `beatnik-=14'."
  (if (> (length beatnik-stack) 0)
      (let (a)
	(setq a (car beatnik-stack)
	      beatnik-stack (cdr beatnik-stack))
	(when (not (= a 0))
	  (if (forward-word 1)
	      (let (n)
		(forward-word -1)
		(setq n (beatnik-word-score (beatnik-next-word)))
		(setq n (beatnik-put-score-in-range n))
		(when (not (backward-word n))
		  (message "not enough words to skip back to (needed %d)." n)))
	    ;; else
	    (message "No argument for skip-back function"))))
    ;; else
    (message "Empty stack. Don't know whether or not to skip words.")))

(defun beatnik-=>18-<=23 ()
  "Does nothing.

However, the score is heigh enough that the Beatnik Interpreter
will not mock you, unless it's had a really bad day."
  (when (< (random 31) 2)
    (message "Deary me, that's stupid of you. Why would you want to say %s?" 
	     (save-excursion
	       (forward-word -1)
	       (beatnik-next-word)))))

(defun beatnik->23 ()
  "Garners \"Beatnik applause\" for the programmer. 

This generally consists of reserved finger-snapping."
  (beep))
  
(defun beatnik-put-score-in-range (score)
  "The numbers beatnik deals with can range from 0 to 255. 

This function checks score to see if it is between 0 and
255 (inclusive). If so, then the score is returned unchanged,
otherwise the number is reduced to a number between 0 and 255 by
decreasing it with 256 repeatedly."
  (cond ((and (< score 256)
	      (> score -1)))
	((< score 0)
	 (while (< score 0)
	   (setq score (+ score 256))))
	((> score 255)
	 (while (> score 255)
	   (setq score (- score 256))))
	(t
	 nil))
  score)

(defvar beatnik-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\, " " st)
    (modify-syntax-entry ?\. " " st)
    (modify-syntax-entry ?\' " " st)
    (modify-syntax-entry ?\* " " st)
    (modify-syntax-entry ?\. " " st)
    (modify-syntax-entry ?\? " " st)
    (modify-syntax-entry ?\! " " st)
    (modify-syntax-entry ?\( " " st)
    (modify-syntax-entry ?\) " " st)
    (modify-syntax-entry ?\" " " st)
    (modify-syntax-entry ?\+ " " st)
    (modify-syntax-entry ?\# " " st)
    (modify-syntax-entry ?\- " " st)
    st)
  "Syntax table in use in beatnik mode buffers.")
	
(defun beatnik-mode ()
  "Major mode for editing beatnik files."
  (interactive)
  (kill-all-local-variables)
  (set-syntax-table beatnik-syntax-table)
  (setq font-lock-keywords-case-fold-search nil) ;; case sensitive keywords
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(beatnik-font-lock-keywords))
  (make-local-variable 'font-lock-keywords-only)
  (setq font-lock-keywords-only t)
  (setq major-mode 'beatnik-mode)
  (setq mode-name "beatnik")
  (use-local-map beatnik-mode-map)

  (run-hooks 'beatnik-mode-hook))

(provide 'beatnik-mode)
