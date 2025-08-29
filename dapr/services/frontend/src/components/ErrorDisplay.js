import React from 'react';

export const ErrorDisplay = ({ error }) => {
  if (!error) return null;

  return (
    <div className="error-message">
      {error}
    </div>
  );
};