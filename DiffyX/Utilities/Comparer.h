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

@property (nonatomic,strong) IBOutlet NSProgressIndicator * _Nullable progressBar;
@property (nonatomic,strong) IBOutlet NSTextField * _Nullable progressMsg;
@property (nonatomic,strong) IBOutlet NSPanel * _Nullable progressPanel;
@property (nonatomic,strong) IBOutlet NSProgressIndicator * _Nullable progressSpinner;
@property (nonatomic,assign) BOOL progressCancelled;
@property (nonatomic,strong) NSMutableString * _Nullable logString;
@property (nonatomic,strong) NSURL * _Nullable logURL;

- (NSMutableArray<NSString *> * _Nullable)listDirectory:(NSString * _Nonnull)pathString;
- (void)weedMissingFromArray:(NSMutableArray * _Nonnull)fromArray
                     InArray:(NSMutableArray * _Nonnull)inArray
                     InTitle:(NSString * _Nonnull)inTitle;
- (IBAction)progressCancel:(id _Nullable)sender;
- (void)doThreadedProcess;
- (void)compareDirectory:(NSString * _Nonnull)fromDir toDirectory:(NSString * _Nonnull)toDir
            withContents:(NSMutableArray * _Nonnull)heirarchy;
- (int)comparePaths;
- (BOOL)compareNewFile:(NSString * _Nonnull)newFile toOldFile:(NSString * _Nonnull)oldFile;
- (BOOL)compareNewFileURL:(NSURL * _Nonnull)newURL toOldFileURL:(NSURL * _Nonnull)oldURL;
- (NSString * _Nullable)checksumForFile:(NSString * _Nonnull)file;
- (NSString * _Nullable)checksumForURL:(NSURL * _Nonnull)url;

- (int)initLog;
- (void)closeLog;

@end

int checksum (NSString * _Nullable file, char * _Nullable checksum_string );
