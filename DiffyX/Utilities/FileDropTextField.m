/*
Diffy Doolittle X -- A File and Directory Comparison Utility.
Copyright (C) 2002  Gregory S. Combs

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#import "FileDropTextField.h"

@implementation FileDropTextField

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSArray *dragTypes = @[NSFilenamesPboardType];
    [self registerForDraggedTypes:dragTypes];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if (!sender || !sender.draggingSource || sender.draggingSource == self)
    {
        if ([super respondsToSelector:@selector(draggingEntered:)])
            return [super draggingEntered:sender];
        return NSDragOperationNone;
    }

    NSColor *aColor = [NSColor grayColor];
    NSPasteboard *pb = [sender draggingPasteboard];
    NSArray *dragTypes = @[NSFilenamesPboardType];
    NSString *type = [pb availableTypeFromArray:dragTypes];
    if (!type)
    {
        if ([super respondsToSelector:@selector(draggingEntered:)])
            return [super draggingEntered:sender];
        return NSDragOperationNone;
    }
    self.backgroundColor = aColor;
    self.editable = NO;
    [self setNeedsDisplay:YES];

    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    NSColor *aColor = [NSColor whiteColor];
    [self setEditable:YES];
    [self setBackgroundColor:aColor];
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pb = [sender draggingPasteboard];
    NSColor *aColor = [NSColor whiteColor];
    NSString *type = [pb availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
    NSArray *array = [[pb stringForType:type] propertyList];
    [self setStringValue:[array objectAtIndex:0]];
    [self setBackgroundColor:aColor];
    [self setEditable:YES];
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    NSColor *aColor = [NSColor whiteColor];
    [self setBackgroundColor:aColor];
    [self setEditable:YES];
    [self setNeedsDisplay:YES];
}

@end
