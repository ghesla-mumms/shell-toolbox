#!/bin/bash

sudo find /Jaspersoft/Administrator/executionLogs/task_$1/ -name "execution*" -type f -printf "%T+\t%p\n" | sort | awk '{print $2}' | tail -1

sudo find /Jaspersoft/Administrator/executionLogs/task_$1/ -name "execution*" -type f -printf "%T+\t%p\n" | sort | awk '{print $2}' | tail -1 | xargs sudo tail -f
