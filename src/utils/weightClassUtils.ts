// Weight Class Utilities - Order and Movement Rules
// Boxers can move up or down 3 weight classes from their original weight class

export const WEIGHT_CLASS_ORDER: string[] = [
  'Strawweight',      // 0
  'Flyweight',        // 1
  'Bantamweight',     // 2
  'Featherweight',    // 3
  'Lightweight',      // 4
  'Welterweight',     // 5
  'Middleweight',     // 6
  'Light Heavyweight', // 7
  'Cruiserweight',    // 8
  'Heavyweight'       // 9
];

/**
 * Get the index of a weight class in the order
 */
export function getWeightClassIndex(weightClass: string): number {
  const index = WEIGHT_CLASS_ORDER.findIndex(
    wc => wc.toLowerCase() === weightClass.toLowerCase()
  );
  return index >= 0 ? index : -1;
}

/**
 * Get weight class name by index
 */
export function getWeightClassByIndex(index: number): string | null {
  if (index < 0 || index >= WEIGHT_CLASS_ORDER.length) return null;
  return WEIGHT_CLASS_ORDER[index];
}

/**
 * Get allowed weight classes (original ± 3)
 */
export function getAllowedWeightClasses(originalWeightClass: string): string[] {
  const originalIndex = getWeightClassIndex(originalWeightClass);
  if (originalIndex < 0) return [];

  const allowedIndices: number[] = [];
  const minIndex = Math.max(0, originalIndex - 3);
  const maxIndex = Math.min(WEIGHT_CLASS_ORDER.length - 1, originalIndex + 3);

  for (let i = minIndex; i <= maxIndex; i++) {
    allowedIndices.push(i);
  }

  return allowedIndices.map(i => WEIGHT_CLASS_ORDER[i]);
}

/**
 * Check if a weight class is allowed for a fighter
 */
export function isWeightClassAllowed(
  originalWeightClass: string,
  newWeightClass: string
): boolean {
  if (!originalWeightClass) return true; // No original class set yet
  const allowed = getAllowedWeightClasses(originalWeightClass);
  return allowed.some(wc => wc.toLowerCase() === newWeightClass.toLowerCase());
}

/**
 * Get the difference in weight classes (positive = up, negative = down)
 */
export function getWeightClassDifference(
  originalWeightClass: string,
  currentWeightClass: string
): number {
  const originalIndex = getWeightClassIndex(originalWeightClass);
  const currentIndex = getWeightClassIndex(currentWeightClass);
  
  if (originalIndex < 0 || currentIndex < 0) return 0;
  
  return currentIndex - originalIndex;
}

/**
 * Check if moving to a new weight class would exceed the ±3 limit
 */
export function wouldExceedWeightClassLimit(
  originalWeightClass: string,
  newWeightClass: string
): boolean {
  if (!originalWeightClass) return false;
  const diff = Math.abs(getWeightClassDifference(originalWeightClass, newWeightClass));
  return diff > 3;
}

