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

/* Controller */

#import <Cocoa/Cocoa.h>
#import "FileDropTextField.h"
#import "Comparer.h"

@interface Controller : NSObject

@property (nonatomic,strong) IBOutlet Comparer *comparer;
@property (nonatomic,strong) IBOutlet NSButton *compResources;
@property (nonatomic,strong) IBOutlet NSButton *delIdentical;
@property (nonatomic,strong) IBOutlet FileDropTextField *fieldNewPath;
@property (nonatomic,strong) IBOutlet FileDropTextField *oldPath;
@property (nonatomic,strong) IBOutlet NSButton *repDifferent;
@property (nonatomic,strong) IBOutlet NSButton *repIdentical;
@property (nonatomic,strong) IBOutlet NSButton *repMissing;

- (IBAction)prefsChanged:(id)sender;
- (IBAction)compare:(id)sender;
- (IBAction)newBrowse:(id)sender;
- (IBAction)oldBrowse:(id)sender;
- (void)forcePrefsUpdate;
@end
