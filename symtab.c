#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "symtab.h"

int traverse(struct scopeTable *head){
        printf("Symbols in table\n");
        while(head!=NULL){
                for(int i=0, j=0; i<MAX && j < head->num; i++){
                        if(head->symArr[i].valid == 1){ 
                                printf("%s\n", head->symArr[i].id);
                                j++;
                        }
                }
                head = head->parent;
        }
        return 1;
}

int addSym(struct scopeTable *head, char* givenId, int lineno, int conType, int dataType, long int strReq){
	int newIndex = head->num;
	strcpy(head->symArr[newIndex].id, givenId);
	head->symArr[newIndex].firstLine = lineno;
	head->symArr[newIndex].lastLine = lineno;
	head->symArr[newIndex].conType = conType;
	if(conType == 1){
	        head->symArr[newIndex].dataType = dataType;
	}
	else if(conType == 2){
	        head->symArr[newIndex].strReq = strReq;
	}
	head->symArr[newIndex].valid = 1;
	head->symArr[newIndex].funcScope = head->scopeNum + 1;
	head->num++;
	return 1;
}

int setVal(struct scopeTable *head, char *id, int lineno, int data){
	while(head!=NULL){
		for(int i=0; i<head->num; i++){
			if(strcmp(head->symArr[i].id, id)==0){
				if(head->symArr[i].conType==1){
				        head->symArr[i].dataType = data;
				        return 1;
				}
				else if(head->symArr[i].conType==2){
				        head->symArr[i].strReq = data;
				        return 1;
				} 
			}
		}
		head = head->parent;
	}
	return 0;	
}

/*int addLookSym(struct scopeTable *head, char* givenId, int add, int lineno, int conType, int data){  
	int found = 0;
	for(int i=0; i<head->num; i++){
		if(strcmp(head->symArr[i].id, givenId)==0){
			found = 1;
			setVal(head, givenId, lineno, data);
			return 1; 
		}
	}
	if(found == 0 && add==1){
		return addSym(head, givenId, lineno, conType, data);
	}
	return 0;
}*/

int findLen(struct scopeTable *head, char *givenId ){
	while(head!=NULL){
		for(int i=0; i<head->num; i++){
			if(strcmp(head->symArr[i].id, givenId)==0){
				return head->symArr[i].strReq / 4;
			}
		}
		head = head->parent;
	}
	return -1;
}

struct scopeTable* addScope(struct scopeTable *head, int scopeNumber){
	struct scopeTable *temp = malloc(sizeof(struct scopeTable));
	for(int i=0; i<MAX; i++){
		temp->symArr[i].valid = 0;
	}
	temp->num = 0;
	temp->parent = head;
	temp->numChild = 0;
	temp->scopeNum = scopeNumber;
	if (head!=NULL){
		head->children[head->numChild] = temp;
		head->numChild++;
	}
	head = temp;
	return head;
}

struct scopeTable* delScope(struct scopeTable *head){
	struct scopeTable *temp = head;
	head = head->parent;
	free(temp);
	return head;
}

struct scopeTable* leaveScope(struct scopeTable *head){
	head = head->parent;
	return head;
}

struct symNode getVal(struct scopeTable *head, char *id, int *succ, int lineno){
	while(head!=NULL){
		for(int i=0; i<head->num; i++){
			if(strcmp(head->symArr[i].id, id)==0){
				*succ = 1;
				head->symArr[i].lastLine = lineno;
				return head->symArr[i];
			}
		}
		head = head->parent;
	}
	*succ = 0;	// if symbol doesn't exist in any scope
	struct symNode res;
	strcpy(res.id, "\0");
	return res;
}

