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

/* Comparer */

#import <Cocoa/Cocoa.h>

@interface Comparer : NSObject

@property (nonatomic,strong) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic,strong) IBOutlet NSTextField *progressMsg;
@property (nonatomic,strong) IBOutlet NSPanel *progressPanel;
@property (nonatomic,strong) IBOutlet NSProgressIndicator *progressSpinner;
@property (nonatomic,assign) BOOL progressCancelled;
@property (nonatomic,strong) NSMutableString *logString;
@property (nonatomic,strong) NSString *logFile;

- (NSMutableArray<NSString *> *)listDirectory:(NSString *)pathString;
- (void)weedMissingFromArray:(NSMutableArray *)fromArray
                     InArray:(NSMutableArray *)inArray
                     InTitle:(NSString *)inTitle;
- (IBAction)progressCancel:(id)sender;
- (void)doThreadedProcess;
- (void)compareDirectory:(NSString *)fromDir toDirectory:(NSString *)toDir
            withContents:(NSMutableArray *)heirarchy;
- (int)comparePaths;
- (BOOL)compareNewFile:(NSString *)newFile toOldFile:(NSString *)oldFile;
- (NSString *)checksumForFile:(NSString *)file;
- (int)initLog;
- (void)closeLog;

@end

int checksum (NSString *file, char * checksum_string);
