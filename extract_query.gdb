# Avoids libary loading issues / more manual work, see bash$ info "(gdb)Auto-loading safe path"
set auto-load safe-path /         
# See http://sourceware.org/gdb/onlinedocs/gdb/Threads.html - this avoids the following issue:
# "warning: unable to find libthread_db matching inferior's threadlibrary, thread debugging will not be available"
set libthread-db-search-path /usr/lib/
set trace-commands on
set pagination off
set print pretty on
set print elements 65536
# Avoids the "'A' <repeats 24 times>" output in returned (query) strings
set print repeats 999999999
set logging file /tmp/gdb_PARSE.txt
set logging on
t 1
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 2
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 3
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 4
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 5
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 6
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 7
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 8
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 9
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 10
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 11
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 12
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 13
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 14
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 15
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 16
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 17
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 18
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 19
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 20
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 21
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 22
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 23
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 24
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 25
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 26
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 27
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 28
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 29
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 30
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 31
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 32
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 33
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 34
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 35
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 36
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 37
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 38
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 39
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 40
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 41
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 42
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 43
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 44
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 45
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 46
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 47
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 48
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 49
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 50
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 51
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 52
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 53
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 54
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 55
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 56
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 57
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 58
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 59
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 60
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 61
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 62
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 63
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 64
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 65
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 66
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 67
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 68
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 69
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 70
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 71
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 72
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 73
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 74
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 75
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 76
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 77
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 78
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 79
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 80
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 81
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 82
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 83
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 84
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 85
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 86
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 87
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 88
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 89
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 90
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 91
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 92
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 93
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 94
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 95
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 96
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 97
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 98
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 99
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 100
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 101
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
t 102
print do_command::thd->query_string.string.str
print do_command::thd->m_query_string.str
set logging off
quit
