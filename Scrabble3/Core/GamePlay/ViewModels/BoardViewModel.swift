//
//  BoardViewModel.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

@MainActor
class BoardViewModel: LetterStoreBase {
    
    @Published var asteriskDialogPresented: Bool = false
    var asteriskRow: Int? = nil
    var asteriskCol: Int? = nil
    
    @Published var moveInfoDialogPresented: Bool = false
    var moveWordsSummary: [(String, WordInfo?, Int)] = []
    var moveTotalScore: Int = 0
    var moveBonus: Int? = nil
    
    override init(lang: GameLanguage) {
        print("BoardViewModel INIT")
        
        super.init(lang: lang)
        let numCells: Int = LetterStoreBase.rows * LetterStoreBase.cols;
        for i in 0...numCells - 1 {
            let row = i / LetterStoreBase.rows
            let col = i % LetterStoreBase.rows
            
            cells.append(CellModel(
                row: row,
                col: col,
                pos: -1,
                letterTile: nil,
                cellStatus: .empty,
                role: .board,
                cellBonus: getCellBonus(row: row, col: col) ?? CellModel.Bonus.none)
            )
        }
    }
    
    var currentMoveCells: [CellModel] {
        return cells.filter({ cell in
            return cell.isCurrentMove
        })
    }
    
    func clearBoard() {
        for idx in cells.indices {
            cells[idx].emptyCell()
        }
    }
    
    func cellByPosition(row: Int, col: Int) -> CellModel {
        let index = row * LetterStoreBase.cols + col
        return cells[index]
    }
    
    func setLetterTileByPosition(row: Int, col: Int, letterTile: LetterTile?) {
        if letterTile != nil && letterTile!.hasAsteriskChar {
            asteriskDialogPresented = true
            asteriskRow = row
            asteriskCol = col
        }
        
        let index = row * LetterStoreBase.cols + col
        cells[index].setTile(tile: letterTile)
        cells[index].setCellStatus(status: !cells[index].isEmpty ? .currentMove : .empty)
    }
    
    func setCellStatusByPosition(row: Int, col: Int, status: CellModel.CellStatus = .error) {
        let index = row * LetterStoreBase.cols + col
        cells[index].setCellStatus(status: status)
    }
    
    func getCellBonus(row: Int, col: Int) -> CellModel.Bonus? {
        let bonus = BonusCells.getBonusCells().first {
            $0.row == row && $0.col == col
        }
        
        if (bonus != nil) {
            return bonus!.bonus
        }
        return CellModel.Bonus.none
    }
    
    func highlightCell(cell: CellModel) {
        setCellStatusByPosition(row: cell.row, col: cell.col)
    }
    
    func highlightWords(words: [WordModel], status: CellModel.CellStatus = .error, timeout: Double = 3.0) {
        for word in words {
            for cell in word.cells {
                setCellStatusByPosition(row: cell.row, col: cell.col, status: status)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.resetCellsStatus()
        }
    }
    
    var getMoveBonus: Int? {
        return currentMoveCells.count == LetterStoreBase.size ? 15 : nil
    }
    
    func getMoveWords() throws -> [WordModel] {
        var words = [WordModel]()
        
        for cell in currentMoveCells {
            var word: WordModel
            var wordBonusK: Int
            var cellConnected = 2
            
            // Horizontal words.
            var anchorCol: Int = cell.col
            
            for col in (0...cell.col).reversed() {
                if (!cellByPosition(row: cell.row, col: col).isEmpty) {
                    anchorCol = col
                } else {
                    break
                }
            }
            word = WordModel(anchorRow: cell.row, anchorCol: anchorCol, direction: .horizontal)
            wordBonusK = 1
            for col in (anchorCol...14) {
                if (cellByPosition(row: cell.row, col: col).isEmpty) {
                    break
                } else {
                    let currentCell = cellByPosition(row: cell.row, col: col)
                    word.word.append(currentCell.letterTile!.char)
                    word.score += currentCell.getCellScore()
                    wordBonusK *= currentCell.getCellWordBonusK()
                    word.cells.append(currentCell)
                    word.isConnectedToExisting = word.isConnectedToExisting || (currentCell.isCenterCell || !currentCell.isCurrentMove)
                }
            }
            
            if (word.isWord) {
                // Apply word bonus.
                word.score *= wordBonusK
                words.append(word)
            } else {
                cellConnected -= 1
            }
            
            // Vertical words.
            var anchorRow: Int = cell.row
            
            for row in (0...cell.row).reversed() {
                if (!cellByPosition(row: row, col: cell.col).isEmpty) {
                    anchorRow = row
                } else {
                    break
                }
            }
            word = WordModel(anchorRow: anchorRow, anchorCol: cell.col, direction: .vertical)
            wordBonusK = 1
            
            for row in (anchorRow...14) {
                if (cellByPosition(row: row, col: cell.col).isEmpty) {
                    break
                } else {
                    let currentCell = cellByPosition(row: row, col: cell.col)
                    word.word.append(currentCell.letterTile!.char)
                    word.score += currentCell.getCellScore()
                    wordBonusK *= currentCell.getCellWordBonusK()
                    word.cells.append(currentCell)
                    word.isConnectedToExisting = word.isConnectedToExisting || (currentCell.isCenterCell || !currentCell.isCurrentMove)
                }
            }
            
            if (word.isWord) {
                // Apply word bonus.
                word.score *= wordBonusK
                words.append(word)
            } else {
                cellConnected -= 1
            }
            
            if (cellConnected == 0) {
                highlightCell(cell: cell)
                throw ValidationError.invalidLetterTilePosition(cell: cell.letterTile!.char)
            }
        }
        
        // Filter duplicates.
        var uniqueWords: [String: WordModel] = [:]
        
        for word in words {
            uniqueWords[word.getHash()] = word
        }
        
        return Array(uniqueWords.values)
    }
    
    func checkWordsConnection(words: [WordModel]) -> [WordModel] {
        var connected: [WordModel] = []
        var hanging: [WordModel] = []
        
        for word in words {
            if (word.isConnectedToExisting) {
                connected.append(word)
            } else {
                hanging.append(word)
            }
        }
        
        while (hanging.count > 0) {
            var validatedIdx: [Int] = []
            
            for idx in hanging.indices {
                for otherWord in connected {
                    if (hanging[idx].intersectsWith(word: otherWord)) {
                        validatedIdx.append(idx)
                    }
                }
            }
            
            if (validatedIdx.count == 0) {
                break
            }
            
            var hangingIdxToRemove: IndexSet = []
            
            for idx in validatedIdx {
                connected.append(hanging[idx])
                hangingIdxToRemove.insert(idx)
            }
            
            hanging.remove(atOffsets: hangingIdxToRemove)
        }
        
        return hanging
    }
    
    func getMoveScore() -> Int {
        do {
            let words = try getMoveWords()
            return words.reduce(0) { $0 + $1.score }
        } catch(ValidationError.invalidLetterTilePosition) {
            return 0
        } catch {
            // Unknown error.
            return 0
        }
    }
    
    func resetCellsStatus() {
        for idx in cells.indices {
            if (!cells[idx].isEmpty) {
                cells[idx].setCellStatus(status: cells[idx].isImmutable ? .immutable : .currentMove)
            }
        }
    }
    
    func confirmMove() {
        for cell in currentMoveCells {
            let index = cell.row * LetterStoreBase.cols + cell.col
            cells[index].setCellStatus(status: .immutable)
            cells[index].isImmutable = true
        }
        resetCellsStatus()
    }
    
//    func setWordsToBoard(words: [WordModel]) {
//        for word in words {
//            for var cell in word.cells {
//                cell.isImmutable = true
//                cell.setCellStatus(status: .immutable)
//                setCellByPosition(row: cell.row, col: cell.col, cell: cell)
//            }
//        }
//    }
    
    func setCellByPosition(row: Int, col: Int, cell: CellModel) {
        let index = row * LetterStoreBase.cols + col
        cells[index] = cell
    }
}

struct BonusCell {
    let row: Int
    let col: Int
    let bonus: CellModel.Bonus
}

struct BonusCells {
    static func getBonusCells() -> [BonusCell] {
        return [
            BonusCell(row: 0, col: 0, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 0, col: 7, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 0, col: 14, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 7, col: 0, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 7, col: 14, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 14, col: 0, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 14, col: 7, bonus: CellModel.Bonus.wordTriple),
            BonusCell(row: 14, col: 14, bonus: CellModel.Bonus.wordTriple),
            
            BonusCell(row: 1, col: 1, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 2, col: 2, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 3, col: 3, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 4, col: 4, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 1, col: 13, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 2, col: 12, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 3, col: 11, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 4, col: 10, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 13, col: 1, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 12, col: 2, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 11, col: 3, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 10, col: 4, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 13, col: 13, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 12, col: 12, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 11, col: 11, bonus: CellModel.Bonus.wordDouble),
            BonusCell(row: 10, col: 10, bonus: CellModel.Bonus.wordDouble),
            
            BonusCell(row: 5, col: 5, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 5, col: 9, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 9, col: 5, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 9, col: 9, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 1, col: 5, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 1, col: 9, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 5, col: 1, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 5, col: 13, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 9, col: 1, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 9, col: 13, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 13, col: 5, bonus: CellModel.Bonus.letterTriple),
            BonusCell(row: 13, col: 9, bonus: CellModel.Bonus.letterTriple),
            
            BonusCell(row: 0, col: 3, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 0, col: 11, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 3, col: 0, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 11, col: 0, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 3, col: 14, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 11, col: 14, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 14, col: 3, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 14, col: 11, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 2, col: 6, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 2, col: 8, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 3, col: 7, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 12, col: 6, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 12, col: 8, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 11, col: 7, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 6, col: 2, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 7, col: 3, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 8, col: 2, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 6, col: 12, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 7, col: 11, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 8, col: 12, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 6, col: 6, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 6, col: 8, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 8, col: 6, bonus: CellModel.Bonus.letterDouble),
            BonusCell(row: 8, col: 8, bonus: CellModel.Bonus.letterDouble)
        ]
    }
}

